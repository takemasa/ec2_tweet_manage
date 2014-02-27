require 'bundler/setup'
Bundler.require

ec2 = AWS::EC2.new(
  access_key_id:     ENV['ACCESS_KEY_ID'],
  secret_access_key: ENV['SECRET_KEY_ID'],
  ec2_endpoint:      'ec2.ap-northeast-1.amazonaws.com'
)

nat_instance = nil
nat_tmp = nil

ec2.instances.each do |instance|
  if instance.tags.to_h["type"] == "tmp_public_ip_assign"
    nat_tmp = instance
    instance.start
    sleep(300)
  elsif instance.tags.to_h["type"] == "public_ip_assign"
    nat_instance = instance
  end
end

ec2.client.replace_route(:route_table_id => 'rtb-cd593ba5', :destination_cidr_block => '0.0.0.0/0', :instance_id=>"#{nat_tmp.id}") # インスタンスがpending, stoppingのときはエラーが発生する
nat_instance.stop
sleep(900)
nat_instance.start
sleep(300)
ec2.client.replace_route(:route_table_id => 'rtb-cd593ba5', :destination_cidr_block => '0.0.0.0/0', :instance_id=>"#{nat_instance.id}")
nat_tmp.stop