require 'bundler/setup'
Bundler.require

ec2 = AWS::EC2.new(
  access_key_id:     ENV['ACCESS_KEY_ID'],
  secret_access_key: ENV['SECRET_KEY_ID'],
  ec2_endpoint:      'ec2.ap-northeast-1.amazonaws.com'
)

    ec2.instances.each do |instance|
        if instance.tags.to_h["type"] == "public_ip_assign"
                instance.stop
                puts "stop #{instance.id}"
    sleep(900)
                instance.start
                puts "start #{instance.id}"
        end
    end
