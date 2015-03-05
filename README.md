# FishtreeBunnyClient

It's a wrapper on bunny gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fishtree_bunny_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fishtree_bunny_client

## Config
Create rabbitmq.yml in config folder

## Usage

Publish a mesage

    FishtreeBunnyClient::Publish.direct('user.updated', {user_ids: user_ids.uniq})


## Contributing

1. Fork it ( https://github.com/[my-github-username]/fishtree_bunny_client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
