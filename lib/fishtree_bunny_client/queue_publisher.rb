require "bunny"
require "yaml"

module FishtreeBunnyClient
  class QueuePublisher
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
	      p "Publishing message [#{message}] to [#{q.name}]"
	      x.publish(message.to_json, routing_key: q.name)
	    rescue => e
	      puts e
	      Airbrake.notify(e) if ENV['RACK_ENV'] == 'staging' or ENV['RACK_ENV'] == 'production'
	    end
	    conn.close
	  end

	end
end
