# FishtreeBunnyClient

It's a wrapper on bunny gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fishtree_bunny_client', '0.0.2', git: 'git@github.com:fishtree/fishtree_bunny_client.git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fishtree_bunny_client

## Config
Create rabbitmq.yml in config folder

## Usage
```ruby
require 'fishtree_bunny_client'
```

Publish a message to queue:

    FishtreeBunnyClient::QueuePublisher.direct('add_message', {message: 'new message'})

Listen messages from queue:

1. Start listener
```ruby
FishtreeBunnyClient::QueueListener.new(ENV['RACK_ENV']).run
```

2. Add listener config `fishtree_queue_listener.yml` in config folder
```ruby
queue1:
	name: 'group_event.create' # name of queue
	class: 'GroupEventCreateQueue' # name of class that handle business logic for queue
queue2:
	name: 'group_event.like_unliked'
	class: 'GroupEventLikeUnlikedQueue'
```
3. Create `queue` folder at root of project
4. Create queue class in `queue` folder
```ruby
class GroupEventCreateQueue
	def process(params)
		p "#{self.class} is processing params [#{params}]"	
		GroupEvent.create_group_event(params['user_id'])
	end
end
```




## Contributing

1. Fork it ( https://github.com/[my-github-username]/fishtree_bunny_client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
