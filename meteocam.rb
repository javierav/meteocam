require 'yaml'
require 'aws-sdk-s3'
require 'httpclient'
require 'httpi'

#
## Configuration
#
@config = YAML.load_file(File.expand_path('../config.yml', __FILE__))

HTTPI.log = false

Aws.config.update({
  region: @config['aws']['region'],
  credentials: Aws::Credentials.new(@config['aws']['key'], @config['aws']['secret'])
})

#
## Download video capture
#
request = HTTPI::Request.new(@config['camera']['url'])
request.auth.digest(@config['camera']['username'], @config['camera']['password'])
response = HTTPI.get(request)

if response.code == 200
  #
  ## Save video capture in Amazon S3
  #
  client = Aws::S3::Client.new
  filename_time = Time.now.strftime('%Y/%m/%d/%H/%Y%m%d%H%M%S')

  # historical archive
  client.put_object({
    body: response.raw_body,
    bucket: @config['aws']['bucket'],
    key: "#{filename_time}-webcam.jpeg"
  })

  # copy to the latest image
  client.copy_object({
    bucket: @config['aws']['bucket'],
    copy_source: "#{filename_time}-webcam.jpeg",
    key: 'latest-webcam.jpeg'
  })
end
