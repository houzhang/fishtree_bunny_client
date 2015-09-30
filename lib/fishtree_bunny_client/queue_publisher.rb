require "bunny"
require "yaml"

module FishtreeBunnyClient
  class QueuePublisher
	  def self.publish(queue, message)
	    if ['production', 'staging'].include? ENV["RACK_ENV"]
	        conn = Bunny.new(ENV["RABBITMQ_URL_INT"])
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
	        conn = Bunny.new(ENV["RABBITMQ_URL_INT"])
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

class QueueListener
		attr_accessor :env, :channel, :queues, :queue_config

		def initialize(env)
	    @env = env
	    @queues = []
	    @queue_config = {}
	  end

		def run
			@env
			if @env.present?
				self.setup
				self.listen
			end
		end

		def setup
			begin
				if ['production', 'staging'].include? ENV["RACK_ENV"]
					conn = Bunny.new(ENV["RABBITMQ_URL_INT"])
				else
					conn = Bunny.new(host: Rabbit[:host], vhost: Rabbit[:vhost], user: Rabbit[:user], password: Rabbit[:password], port: Rabbit[:port])
				end
				conn.start

				@channel = conn.create_channel

				config = YAML.load(File.read(File.expand_path('config/fishtree_queue_listener.yml')))

				config.each do |key, value|
					@queues << @channel.queue("#{value['name']}_#{@env}")
					@queue_config[value['name']] = value['class']
					puts "Subscribing to queue [#{@queues.last.name}]"
				end
			rescue => e
		  	puts e
		    Airbrake.notify(e) if env == 'staging' or env == 'production'
		  end		
		end

		def listen
			@queues.each do |queue|
				queue.subscribe(block: false, manual_ack: true) do |delivery_info, properties, body|	
					begin
				  	params = JSON.parse(body)

				  	p "Processing queue [#{queue.name}] for params [#{params}]"	
						require(File.expand_path("queue/#{@queue_config[queue.name.gsub("_#{@env}", '')].underscore}"))
						queue_class = YAML.load "--- !ruby/object:#{@queue_config[queue.name.gsub("_#{@env}", '')]} {}"
						queue_class.process(params)
				  rescue => e
				  	puts e
				  	Airbrake.notify(e) if env == 'staging' or env == 'production'
				  end
				  # acknowledge event has been received and responded
					@channel.ack(delivery_info.delivery_tag)
				end
			end	
		end

	end

end
