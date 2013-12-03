require 'bundler/setup'
Bundler.require

config = YAML.load(File.read("./config/aws.yaml"))
AWS.config(config)

ec2 = AWS::EC2.new(config)

    ec2.instances.each do |instance|
        if instance.tags.to_h["type"] == "public_ip_assign"
                instance.stop
                puts "stop #{instance.id}"
    sleep(900)
                instance.start
                puts "start #{instance.id}"
        end
    end
