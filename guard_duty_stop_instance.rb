# set lambda timeout to 15 seconds
require 'aws-sdk'

def lambda_handler(event:, context:)
  region = "" # required
  detail = event['detail']

  if detail['service']['serviceName'] == 'guardduty' && detail['service']['resourceRole'] == "TARGET" && detail['resource']['resourceType'] == "Instance"
    instance_id = detail['resource']['instanceDetails']['instanceId']

    begin
      ec2 = Aws::EC2::Client.new(region: 'us-east-2')

      # rename the compromised instance
      ec2.create_tags({
        resources: [instance_id],
        tags: [
          {
            key: "Name",
            value: "DANGER - DO NOT RESTART - COMPROMISED",
          }
        ]
      })

      # stop the compromised instance
      ec2.stop_instances({ instance_ids: [instance_id] })

      # send sns e-mail
      send_notification(detail, region)
    rescue Aws::EC2::Errors::ServiceError => e
      raise "Stop EC2 Instance error: #{e}"
    end
  end
end

private

def send_notification(detail, region)
  begin
    sns = Aws::SNS::Client.new(region: region)
    sns_topic_arn = "" # required
    subject = "GuardDuty: Compromised EC2 instance was stopped"

    message = "The instance #{detail['resource']['instanceDetails']['instanceId']} was stopped and tagged as compromised.\n"
    message += "Reason:\n\n#{detail['title']}\n#{detail['description']}"

    sns.publish({
      topic_arn: sns_topic_arn,
      message: message,
      subject: subject
    })
  rescue Aws::SNS::Errors::ServiceError => e
    raise "GuardDuty to SNS send e-mail error: #{e}"
  end
end
