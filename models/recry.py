from twilio.rest import Client
import dotenv

# Load the environment variable so we don't hardcode stuff
dotenv.load()

# Your Account SID from twilio.com/console
account_sid = dotenv.get('TWILIO_ACCOUNT_SID')
# Your Auth Token from twilio.com/console
auth_token  = dotenv.get('TWILIO_ACCOUNT_AUTH_TOKEN')

client = Client(account_sid, auth_token)

message = client.messages.create(
    to="+12628931037", 
    from_="+2628931037",
    body="Hello from Python!")

print(message.sid)
