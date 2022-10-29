User.create! first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, admin: true, months_subscribed: 1
User.create! first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, moderator: true, months_subscribed: 24

35.times do 
  User.create! first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, months_subscribed: 10
end