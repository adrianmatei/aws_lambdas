require 'aws-sdk-sns'
require 'json'

def lambda_handler(event:, context:)
  sns = Aws::SNS::Client.new
  topic_arn = "" # required

  message = "Threat type: #{event['detail']['type']} \n"
  message += "Description: #{event['detail']['description']} \n"
  message += event.to_s
  subject = event['detail']['title']

  begin
    sns.publish({
      topic_arn: topic_arn,
      message: message,
      subject: subject
    })
  rescue Aws::SNS::Errors::ServiceError => e
    raise "GuardDuty to SNS send e-mail error: #{e}"
  end
end
