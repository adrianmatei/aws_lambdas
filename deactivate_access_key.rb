require 'aws-sdk-iam'
require 'json'

def lambda_handler(event:, context:)
  detail = event['detail']
  iam = Aws::IAM::Client.new

  if detail['service']['serviceName'] == 'guardduty' && detail['service']['resourceRole'] == "TARGET" && detail['resource']['resourceType'] == "AccessKey" && detail['severity'] >= 5
    access_details = detail['resource']['accessKeyDetails']

    begin
      iam.update_access_key({
        access_key_id: access_details['accessKeyId'],
        status: "Inactive",
        user_name: access_details['userName'],
      })
    rescue Aws::IAM::Errors::ServiceError => e
      raise "Deactivate IAM user access key error: #{e}"
    end
  end
end
