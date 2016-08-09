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

def to_dataset(data, label)
  {
    label: label,
    fillColor: 'rgba(220,220,220,0.5)',
    strokeColor: 'rgba(220,220,220,0.8)',
    highlightFill: 'rgba(220,220,220,0.75)',
    highlightStroke: 'rgba(220,220,220,1)',
    data: data,
  }
end

options = { scaleFontColor: '#fff' }


SCHEDULER.every '10m', :first_in => 0 do 
  # Pull Wunderlist tasks and get a list of completion times
  lists = wunderlist.lists
  completed_at_times = lists.map do |list|
    list.tasks(completed: true).map(&:completed_at)
  end.flatten.map { |s| DateTime.iso8601(s) }

  # Get completion data about last week
  last_week = completed_at_times.select { |t| t > (Date.today - 7) }
  
  last_week_data = {}

  (1..7).reverse_each do |i|
    day = (Date.today - i)
    day_tasks = last_week.select { |t| t === day }.count
    last_week_data[day.strftime("%A")] = day_tasks
  end

  # Get number of completions for 'today'
  completed_today = completed_at_times.select { |t| t === Date.today }.count

  # Send events
  send_event('wunderlist_completed_today', current: completed_today)
  send_event('wunderlist_last_week', { labels: last_week_data.keys,
    datasets: [to_dataset(last_week_data.values, 'Tasks Completed Last Week')],
    options: options })
end
