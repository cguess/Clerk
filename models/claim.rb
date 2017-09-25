require 'sequel'
require 'httparty'
require 'byebug'

class Claim < Sequel::Model
	many_to_one :site

  include HTTParty
  base_uri ENV['CHAMBERLAIN_URL']

  def after_save
  	super
  	upload
  end

  # This takes a Mida-parsed microdata and transforms it into the JSON-microdata equivolent, which is what Chamberlain knows how to read.
  def self.json_from_microdata microdata
  	begin
	  	properties = microdata.properties
	  	url = properties['url'][0]
	  	source_url = 	
	  	image = {}
	  	image[:url] = properties['image'][0].properties['url'][0]
	  	image[:width] = properties['image'][0].properties['width'][0]
			image[:height] = properties['image'][0].properties['height'][0]
			author = {}
			author[:url] = properties['author'][0].properties['url'][0]
			author[:name] = properties['author'][0].properties['name'][0]
			headline = properties['headline'][0]
			date_modified = properties['dateModified'][0]
			item_reviewed = {}
			item_reviewed[:author] = {}
			item_reviewed[:author][:name] = properties['itemReviewed'][0].properties['author'][0].properties['name'][0]
			item_reviewed[:author][:same_as] = properties['itemReviewed'][0].properties['author'][0].properties['sameAs'][0] if properties['itemReviewed'][0].properties['author'][0].properties.has_key?('sameAs')
			review_rating = {}
			review_rating[:best_rating] = properties['reviewRating'][0].properties['bestRating'][0]
			review_rating[:rating_value] = properties['reviewRating'][0].properties['ratingValue'][0]
			review_rating[:worst_rating] = properties['reviewRating'][0].properties['worstRating'][0]
			review_rating[:alternate_name] = properties['reviewRating'][0].properties['alternateName'][0]
			claim_reviewed = properties['claimReviewed'][0]
			date_published = properties['datePublished'][0]
		rescue Exception => e
			return nil
		end

	 	data = {}
	 	data[:@context] = "http://schema.org"
	 	data[:@type] = "ClaimReview"
	 	data[:datePublished] = date_published
	 	data[:url] = url
	 	data[:author] = {}
	 	data[:author][:@type] = "Organization"
	 	data[:author][:url] = author[:url] if author.has_key? :url
	 	data[:author][:name] = author[:name] if author.has_key? :name
	 	data[:author][:sameAs] = author[:same_as] if author.has_key? :same_as
	 	data[:claimReviewed] = claim_reviewed
	 	data[:reviewRating] = {}
	 	data[:reviewRating][:@type] = 'Rating'
	 	data[:reviewRating][:ratingValue] = review_rating[:rating_value]
	 	data[:reviewRating][:bestRating] = review_rating[:best_rating]
	 	data[:reviewRating][:worstRating] = review_rating[:worst_rating]
	 	data[:reviewRating][:alternateName] = review_rating[:alternate_name] if review_rating.has_key? :alternate_name
	 	data[:reviewRating][:image] = review_rating[:image] if review_rating.has_key? :image
	 	data[:itemReviewed] = {}
	 	data[:itemReviewed][:@type] = "CreativeWork"
	 	data[:itemReviewed][:author] = {}
	 	data[:itemReviewed][:author][:@type] = "Person"
	 	data[:itemReviewed][:author][:name] = item_reviewed[:author][:name]
	 	data[:itemReviewed][:author][:sameAs] = item_reviewed[:author][:same_as] if item_reviewed.has_key? :same_as
	 	data[:itemReviewed][:author][:jobTitle] = item_reviewed[:author][:job_title] if item_reviewed.has_key? :job_title
	 	data[:itemReviewed][:author][:image] = item_reviewed[:author][:image] if item_reviewed.has_key? :image

	 	return data.to_json
  end
=begin

	{
    "@context": "http://schema.org",
    "@type": "ClaimReview",
    "datePublished": "2014-07-23",
    "url": "http://www.politifact.com/texas/statements/2014/jul/23/rick-perry/rick-perry-claim-about-3000-homicides-illegal-immi/",
    "author": {
        "@type": "Organization",
        "url": "http://www.politifact.com/",
        "image": "http://static.politifact.com/mediapage/jpgs/politifact-logo-big.jpg",
        "sameAs": "https://twitter.com/politifact"
    },
    "claimReviewed": "More than 3,000 homicides were committed by \"illegal aliens\" over the past six years.",
    "reviewRating": {
        "@type": "Rating",
        "ratingValue": 1,
        "bestRating": 6,
        "image": "http://static.politifact.com.s3.amazonaws.com/rulings/tom-pantsonfire.gif",
        "alternateName": "True"
    },
    "itemReviewed": {
        "@type": "CreativeWork",
        "author": {
            "@type": "Person",
            "name": "Rich Perry",
            "jobTitle": "Former Governor of Texas",
            "image": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Gov._Perry_CPAC_February_2015.jpg/440px-Gov._Perry_CPAC_February_2015.jpg",
            "sameAs": [
                "https://en.wikipedia.org/wiki/Rick_Perry",
                "https://rickperry.org/"
            ]
        },
        "datePublished": "2014-07-17",
        "name": "The St. Petersburg Times interview [...]"
    }
}


		return json_error "Request missing full_text", 2001 if fact['full_text'].blank?
		return json_error "Request missing microdata", 2001 if fact['microdata'].blank?
		return json_error "Request missing source_url", 2001 if fact['source_url'].blank?
		return json_error "Request missing site_id", 2001 if fact['site_id'].blank?
		return json_error "Request missing claim_reviewed", 2001 if fact['claim_reviewed'].blank?
		return json_error "Request missing author_type", 2001 if fact['author_type'].blank?
		return json_error "Request missing author_url", 2001 if fact['author_url'].blank?
		return json_error "Request missing author_image", 2001 if fact['author_image'].blank?
		return json_error "Request missing author_same_as", 2001 if fact['author_same_as'].blank?
		return json_error "Request missing review_type", 2001 if fact['review_type'].blank?
		return json_error "Request missing review_rating_value", 2001 if fact['review_rating_value'].blank?
		return json_error "Request missing review_best_rating", 2001 if fact['review_best_rating'].blank?
		return json_error "Request missing review_image", 2001 if fact['review_image'].blank?
		return json_error "Request missing review_alternate_name", 2001 if fact['review_alternate_name'].blank?
		return json_error "Request missing item_reviewed_type", 2001 if fact['item_reviewed_type'].blank?
		return json_error "Request missing item_reviewed_date_published", 2001 if fact['item_reviewed_date_published'].blank?
		return json_error "Request missing item_reviewed_name", 2001 if fact['item_reviewed_name'].blank?
		return json_error "Request missing item_reviewed_author_type", 2001 if fact['item_reviewed_author_type'].blank?
		return json_error "Request missing item_reviewed_author_name", 2001 if fact['item_reviewed_author_name'].blank?
		return json_error "Request missing item_reviewed_author_job_title", 2001 if fact['item_reviewed_author_job_title'].blank?
		return json_error "Request missing item_reviewed_author_image", 2001 if fact['item_reviewed_author_image'].blank?
		return json_error "Request missing item_reviewed_author_same_as", 2001 if fact['item_reviewed_author_same_as'].blank?

 {
	"id": null,
	"type": "http://schema.org/ClaimReview",
	"properties": {
		"url": ["http://www.snopes.com/trump-wall-comic-strip/"],
		"image": [{
			"id": null,
			"type": "http://schema.org/ImageObject",
			"properties": {
				"url": ["http://static.snopes.com/app/uploads/2017/09/The_Wall_Peter_Kuper_FB-865x452.jpg"],
				"width": ["865"],
				"height": ["452"]
			},
			"vocabulary": {
				"itemtype": "(?-mix:)",
				"properties": {
					"any": {
						"num": "many",
						"types": ["any"]
					}
				},
				"this_properties": {
					"any": {
						"num": "many",
						"types": ["any"]
					}
				},
				"included_vocabularies": []
			}
		}],
		"author": [{
			"id": null,
			"type": "http://schema.org/Organization",
			"properties": {
				"url": ["http://www.snopes.com"],
				"name": ["snopes"]
			},
			"vocabulary": {
				"itemtype": "(?-mix:)",
				"properties": {
					"any": {
						"num": "many",
						"types": ["any"]
					}
				},
				"this_properties": {
					"any": {
						"num": "many",
						"types": ["any"]
					}
				},
				"included_vocabularies": []
			}
		}],
		"headline": ["Did a 1990 Comic Depict Trump Coming to Power and Building a Wall?"],
		"dateModified": ["2017-09-22T13:06:27+00:00"],
		"itemReviewed": [{
			"id": null,
			"type": "http://schema.org/CreativeWork",
			"properties": {
				"author": [{
					"id": null,
					"type": "http://schema.org/Organization",
					"properties": {
						"name": ["Steve Lieber/Twitter"],
						"sameAs": ["https://twitter.com/steve_lieber/status/910575231667806208"]
					},
					"vocabulary": {
						"itemtype": "(?-mix:)",
						"properties": {
							"any": {
								"num": "many",
								"types": ["any"]
							}
						},
						"this_properties": {
							"any": {
								"num": "many",
								"types": ["any"]
							}
						},
						"included_vocabularies": []
					}
				}],
				"datePublished": ["2017-09-22T11:09:21+00:00"]
			},
			"vocabulary": {
				"itemtype": "(?-mix:)",
				"properties": {
					"any": {
						"num": "many",
						"types": ["any"]
					}
				},
				"this_properties": {
					"any": {
						"num": "many",
						"types": ["any"]
					}
				},
				"included_vocabularies": []
			}
		}],
		"reviewRating": [{
			"id": null,
			"type": "http://schema.org/Rating",
			"properties": {
				"bestRating": ["-1"],
				"ratingValue": ["-1"],
				"worstRating": ["-1"],
				"alternateName": ["TRUE"]
			},
			"vocabulary": {
				"itemtype": "(?-mix:)",
				"properties": {
					"any": {
						"num": "many",
						"types": ["any"]
					}
				},
				"this_properties": {
					"any": {
						"num": "many",
						"types": ["any"]
					}
				},
				"included_vocabularies": []
			}
		}],
		"claimReviewed": ["A July 1990 comic strip in Heavy Metal magazine featured a controversial wall in New York City, built by Donald Trump, and a populist \"rise to power \" by the future president."],
		"datePublished": ["2017-09-22T11:09:21+00:00"]
	},
	"vocabulary": {
		"itemtype": "(?-mix:)",
		"properties": {
			"any": {
				"num": "many",
				"types": ["any"]
			}
		},
		"this_properties": {
			"any": {
				"num": "many",
				"types": ["any"]
			}
		},
		"included_vocabularies": []
	}
}
=end

	def upload
		options = {body: self.options.to_json, headers: {'Content-Type': 'appliation/json', 'Accept': 'application/json'}}
		self.class.post "/facts.json", options
	end

	def options
		options = {}
		options[:client_uuid] = ENV['CLIENT_UUID']
		options[:api_key] = ENV['API_KEY']
		options[:fact] = JSON.parse(self.claim_data)
		options[:fact][:full_text] = self.claim_data
		options[:fact][:source_url] = self.site.url
		options[:fact][:site_id] = self.site_id
		options[:fact][:microdata] = self.claim_data
		return options
	end
end