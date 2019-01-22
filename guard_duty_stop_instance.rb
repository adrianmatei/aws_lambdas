require 'aws-sdk-ec2'
require 'json'

def lambda_handler(event:, context:)
  ec2 = Aws::EC2::Client.new(region: '')
  instance_id = event['detail']['resource']['instanceDetails']['instanceId']

  begin
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
  rescue Aws::EC2::Errors::ServiceError => e
    raise "Stop EC2 Instance error: #{e}"
  end
end
