require "bunny"
require "yaml"

class QueueListener
	attr_accessor :env, :channel, :queues, :queue_config

	def initialize(env)
    @env = env
    @queues = []
    @queue_config = {}
  end

	def run
		self.setup
		self.listen
	end

	def setup
		begin
			if ['production', 'staging'].include? ENV["RACK_ENV"]
				conn = Bunny.new(host: Rabbit[:host], vhost: Rabbit[:vhost], user: Rabbit[:user], password: Rabbit[:password], heartbeat: 100)
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

			  	p "Processing #{queue.name} for params [#{params}]"	
					p "../queue/#{@queue_config[queue.name.gsub("_#{@env}", '')].underscore}"
					require_relative "../queue/#{@queue_config[queue.name.gsub("_#{@env}", '')].underscore}"
					p queue_class = YAML.load "--- !ruby/object:#{@queue_config[queue.name.gsub("_#{@env}", '')]} {}"
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