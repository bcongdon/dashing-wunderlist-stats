# ./job/wunderlist_stats.rb

require 'wunderlist'
require 'yaml'

yaml_file = "./conf/wunderlist_stats.yaml"
if File.exist? yaml_file
  WUNDERLIST_STATS_CONFIG = YAML.load_file(yaml_file)
else
  WUNDERLIST_STATS_CONFIG = {
    access_token: "",
    client_id: "" 
  }
end

wunderlist = Wunderlist::API.new WUNDERLIST_STATS_CONFIG

SCHEDULER.every '5m', :first_in => 0 do 
  lists = wunderlist.lists

  completed_at_times = lists.map do |list|
    list.tasks(completed: true).map(&:completed_at)
  end.flatten.map { |s| DateTime.iso8601(s) }

  completed_today = completed_at_times.select { |t| t > Date.today }.count

  send_event('wunderlist_completed_today', current: completed_today)
end
