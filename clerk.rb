require 'rubygems'
require 'mechanize'
require 'sequel'
require 'byebug'
require 'mida'
require 'time_difference'

require_relative 'models/database'


class Scraper

	@url = nil
	@db_connection = nil
	@agent = nil
	@errors = []

	def scrape
		raise "No URL set for this instance of 'Scraper'" if @url.nil?

		sites_dataset = @@DB[:sites]
		url = ENV['URL']
		sites = Site.where{url == url}

		if sites.count < 1
			Site.create(url: url, base_url:ENV['URL'])
			sites = Site.where{url == url}
		end

		@agent = Mechanize.new
		url, links = scrape_page sites.first
		save_sites links
		
		# if links.nil?
		# 	print "\n**************\n"
		# 	print "Page has been scanned recently, to force use... something\n"
		# 	print "**************\n\n"
		# 	return
		# end
		
		minutes = 3
		loop do
			time_ago = DateTime.now - (minutes/1440.0)
			sites = Site.where{last_visited < time_ago}
			if sites.nil? || sites.all.count == 0
				print "\n**************\n"
				print "Sleeping for #{60 * minutes}\n"
				print "**************\n\n"

				sleep 60 * minutes
				next
			end
			
			sites.each do |site|
				url, links = scrape_page site
				
				next if links.nil?
				save_sites links
#				links.each do |link|
					#new_url, new_links = scrape_page link.href
#					save_sites new_links
#				end
			end

			print "\n**************\n"
			print "Restarting search for new sites\n"
			print "**************\n\n"

		end
	end

	def scrape_page site
		
		begin
			url = site[:url]
		rescue Exception => e
			byebug
		end

		# If it's an off-page link, ignore it
		return unless url.start_with?(ENV['URL'])

		# If the page throws an error (404 for instance), ignore it
		begin
			page = @agent.get(url)
		rescue Exception => e
			return
		end

		sites_dataset = @@DB[:sites]

		# Attempt to find if the site is in the database already
		site = Site.first(url: url)
		# If the site's in the database, and has been visited in the last day, skip it.
		return if TimeDifference.between(site[:last_visited], Time.now).in_hours < 0
	
		pp "Scraping: #{url}"

		found_claims = search_for_microdata page.content
		save_claims(found_claims, site)

		site.last_visited = Time.now
		site.save

		return url, page.links
	end

	def search_for_microdata content
		parsed = Mida::Document.new content
		claims = parsed.search(%r{http://schema.org/ClaimReview}i)
	end

	def save_claims claims, site
		claims_dataset = @@DB[:claims]

		claims.each do |claim|
			hashed_json = Digest::SHA256.hexdigest claim.to_json
			next unless claims_dataset.first(hash: hashed_json).nil?
			json = Claim.json_from_microdata(claim)
			next if json.nil?
			claim_object = Claim.create(claim_data: json, hash:hashed_json, last_visited: Time.now, site_id: site[:id])
		end
	end

	def save_sites sites
		sites_dataset = @@DB[:sites]
		
		return if sites.nil?

		sites.each do |site|
			next unless Site.first(url: site.href).nil?
			next unless site.href.start_with? ENV['URL']
			id = Site.create(url: site.href, base_url:ENV['URL'])
		end
	end

	def url= url
		@url = url
	end

end



def verify_setup

	raise "No 'URL' environment variable set" unless ENV['URL']

end

def run
	@@DB = Database.new.setup

	require_relative 'models/site'
	require_relative 'models/claim'

	scraper =	Scraper.new
	scraper.url = ENV['URL']
	scraper.scrape
end

run