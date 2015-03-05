require "bunny"
require "yaml"
require "fishtree_bunny_client/version"

Rabbit = YAML.load(File.read(File.expand_path('config/rabbitmq.yml')))
Rabbit.merge! Rabbit.fetch(ENV['RACK_ENV'], {}).each_with_object({}){|(k,v), h| h[k.to_sym] = v}

module FishtreeBunnyClient
  class Publish
	  def self.publish(queue, message)
	    if ['production', 'staging'].include? ENV["RACK_ENV"]
	        conn = Bunny.new(Rabbit[:string])
	      else
	        conn = Bunny.new(host: Rabbit[:host], vhost: Rabbit[:vhost], user: Rabbit[:user],
	                       password: Rabbit[:password], port: Rabbit[:port].to_s)
	      end
	    begin
	      conn.start

	      ch = conn.create_channel
	      x  = ch.fanout("#{queue}_#{ENV['RACK_ENV']}")
	      x.publish(message.to_json, routing_key: x.name)
	    rescue => e
	      puts e
	      Airbrake.notify(e) if ENV['RACK_ENV'] == 'staging' or ENV['RACK_ENV'] == 'production'
	    end
	    conn.close
	  end

	  def self.direct(queue, message)
	    if ['production', 'staging'].include? ENV["RACK_ENV"]
	        conn = Bunny.new(Rabbit[:string])
	      else
	        conn = Bunny.new(host: Rabbit[:host], vhost: Rabbit[:vhost], user: Rabbit[:user],
	                       password: Rabbit[:password], port: Rabbit[:port].to_s)
	      end
	    begin
	      conn.start

	      ch = conn.create_channel
	      q  = ch.queue("#{queue}_#{ENV['RACK_ENV']}")
	      x  = ch.default_exchange
	      x.publish(message.to_json, routing_key: q.name)
	    rescue => e
	      puts e
	      Airbrake.notify(e) if ENV['RACK_ENV'] == 'staging' or ENV['RACK_ENV'] == 'production'
	    end
	    conn.close
	  end


	  def self.rabbit
	    p File.expand_path('config/rabbitmq.yml')
	  end
	end
end
