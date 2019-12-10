require 'rss'
require 'open-uri'
require 'byebug'
require 'pry'
require 'slugify'

def feed_xml_to_json(feed_url)
  open(feed_url) do |rss|
    puts "Requesting data from #{feed_url}..."
    feed = RSS::Parser.parse(rss)
    feed_data = Array.new
    feed_meta = {
      feed_owner: (feed.channel.itunes_owner.itunes_name rescue nil),
      feed_title: (feed.channel.title rescue nil),
      feed_desc: (feed.channel.description rescue nil),
      feed_lang: (feed.channel.language rescue nil),
      feed_last_built: (feed.channel.lastBuildDate rescue nil),
      feed_cvr_img: (feed.channel.itunes_image rescue nil),
      feed_category: (feed.channel.itunes_category rescue nil)
    }
    feed_data << feed_meta
    episodes = Array.new
    feed.items.each_with_index do |item, n|
      episode = {
        episode_title: (item.title.strip rescue nil),
        episode_desc: (item.description.strip rescue nil),
        episode_pub_date: (item.pubDate rescue nil),
        episode_author: (item.itunes_author rescue nil),
        episode_duration_unix: (item.enclosure.length rescue nil),
        episode_duration: (item.itunes_duration.content rescue nil),
        episode_format: (item.enclosure.type rescue nil),
        episode_url: (item.enclosure.url rescue nil),
        episode_keywords: (item.itunes_keywords rescue nil)
      }
      episodes << episode
    end
    feed_meta.store("episodes", episodes)
    puts "'#{feed_meta[:feed_title]}' succesfully mapped: #{episodes.length} episodes found"
    return feed_meta
  end
end

def process_data
  
  # create new array to store data from each feed 
  all_data = Array.new
  
  # pass urls thru mapping function and store in array
  all_data << feed_xml_to_json("http://feeds.soundcloud.com/users/soundcloud:users:13730980/sounds.rss")
  all_data << feed_xml_to_json("http://feeds.soundcloud.com/users/soundcloud:users:14268499/sounds.rss")
  all_data << feed_xml_to_json("http://rss.acast.com/vintagepodcast")
  # all_data << feed_xml_to_json("http://feeds.soundcloud.com/users/soundcloud:users:8180342/sounds.rss")
  # all_data << feed_xml_to_json("https://www.theguardian.com/books/series/books/podcast.xml")
  # all_data << feed_xml_to_json("http://feeds.soundcloud.com/users/soundcloud:users:313878848/sounds.rss")
  # all_data << feed_xml_to_json("http://feeds.poetryfoundation.org/PoetryOffTheShelf?id=510219")
  # all_data << feed_xml_to_json("https://rss.acast.com/readlikeawriter")
  # all_data << feed_xml_to_json("http://independentpublishersguild.libsyn.com/rss")
  # all_data << feed_xml_to_json("https://feed.pippa.io/public/shows/5ce3bd97862700d1704d3dfb")
  # all_data << feed_xml_to_json("https://feeds.soundcloud.com/users/soundcloud:users:47550828/sounds.rss")
  # all_data << feed_xml_to_json("http://feeds.soundcloud.com/users/soundcloud:users:535574250/sounds.rss")
  # all_data << feed_xml_to_json("https://feeds.fireside.fm/verybadwizards/rss")
  # all_data << feed_xml_to_json("https://rss.acast.com/londonreviewpodcasts")
  # all_data << feed_xml_to_json("http://feeds.soundcloud.com/users/soundcloud:users:1076867/sounds.rss")
  
  # write data to file
  File.open("./_data/all_data.json", "w") do |file|
    file.write(JSON.pretty_generate(all_data))
  end
  
  # flatten data array into one big episodes list
  episodes = all_data.map { |podcast| podcast["episodes"] }.flatten
  
  # write episodes data to file
  File.open("./_data/episodes.json", "w") do |file|
    file.write(JSON.pretty_generate(episodes))
  end
  
  # open episodes data and convert each date string to date and rewrite to file
  json = JSON.parse(File.read("./_data/episodes.json"))
  json = json.each do |episode|
    episode["episode_pub_date"] = Date.parse(episode["episode_pub_date"])
  end
  File.open("./_data/episodes.json", "w") do |file|
    file.write(JSON.pretty_generate(json))
  end
  
  # summarize
  puts "#{all_data.length} podcasts scraped for #{all_data.map { |podcast| podcast['episodes'] }.flatten.length} episodes"
end

def remap_data
  json = JSON.parse(File.read("./_data/all_data.json"))
  json = json.each do |feed|
    feed["episodes"].each do |episode|
      episode["episode_pub_date"] = Date.parse(episode["episode_pub_date"])
      episode["episode_feed_title"] = feed["feed_title"]
      episode["episode_feed_cvr_img"] = URI.extract(feed["feed_cvr_img"]).last
    end
  end
  json = json.map { |podcast| podcast["episodes"] }.flatten.sort_by { |k| k["episode_pub_date"] }.reverse
  File.open("./_data/mapped_data.json", "w") do |file|
    file.write(JSON.pretty_generate(json.take(10)))
  end
end

process_data
remap_data