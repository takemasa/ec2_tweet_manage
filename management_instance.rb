require 'bundler/setup'
Bundler.require

ec2 = AWS::EC2.new(
  access_key_id:     ENV['ACCESS_KEY_ID'],
  secret_access_key: ENV['SECRET_KEY_ID'],
  ec2_endpoint:      'ec2.ap-northeast-1.amazonaws.com'
)

nat = nil
nat_tmp = nil
etl = nil
ec2.instances.each do |instance|
  case instance.tags.to_h["type"]
  when "redshift_etl"
    etl = instance # RedshiftへのETL処理を行うインスタンス
  when "tmp_public_ip_assign"
    nat_tmp = instance # natの停止中に動作するNATインスタンス
  when "public_ip_assign"
    nat = instance # メインで利用されるNATインスタンス
  end
end

etl.start #etlインスタンスの起動中にcronで設定された処理が行われる
nat_tmp.start
sleep(5*60)
# ルートテーブルをnatからnat_tmpに付け替え
ec2.client.replace_route(:route_table_id => 'rtb-cd593ba5', :destination_cidr_block => '0.0.0.0/0', :instance_id=>"#{nat_tmp.id}") # インスタンスがpending, stoppingのときはエラーが発生する
nat.stop
sleep(15*60)
nat.start
sleep(5*60)
# natの再起動後にルートテーブルを戻すとIPアドレスが変わる
ec2.client.replace_route(:route_table_id => 'rtb-cd593ba5', :destination_cidr_block => '0.0.0.0/0', :instance_id=>"#{nat.id}")
nat_tmp.stop
sleep(60*60)
etl.stop