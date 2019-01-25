# set lambda timeout to 15 seconds
require 'aws-sdk'

def lambda_handler(event:, context:)
  region = "" # required
  detail = event['detail']

  if detail['service']['serviceName'] == 'guardduty' && detail['service']['resourceRole'] == "TARGET" && detail['resource']['resourceType'] == "AccessKey" && detail['severity'] >= 5
    access_details = detail['resource']['accessKeyDetails']

    begin
      iam = Aws::IAM::Client.new(region: region)
      iam.update_access_key({
        access_key_id: access_details['accessKeyId'],
        status: "Inactive",
        user_name: access_details['userName'],
      })

      send_notification(detail, region)
    rescue Aws::IAM::Errors::ServiceError => e
      raise "Deactivate IAM user access key error: #{e}"
    end
  end
end

private

def send_notification(detail, region)
  begin
    sns = Aws::SNS::Client.new(region: region)
    sns_topic_arn = "" # required
    subject = "GuardDuty: IAM user access key was disabled"

    message = "The access key was deactivated for user #{detail['resource']['accessKeyDetails']['userName']}. \n\n"
    message += "Reason:\n#{detail['title']}\n#{detail['description']}"

    sns.publish({
      topic_arn: sns_topic_arn,
      message: message,
      subject: subject
    })
  rescue Aws::SNS::Errors::ServiceError => e
    raise "GuardDuty to SNS send e-mail error: #{e}"
  end
end
