# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

project = Project.create_with(logo_url: 'https://placehold.co/300x300', welcome_text: 'Welcome text for First Project').find_or_create_by(title: 'First Project')
plot_polygon = 'POLYGON ((-0.002001 51.477865, -0.001886 51.477912, -0.001918 51.477805, -0.002001 51.477865))'
plot = project.plots.create_with(tile_population_status: 'succeeded', description: 'Description for First Plot', polygon: plot_polygon).find_or_create_by(title: 'First Plot')

plot.tiles.create_with(southwest: 'POINT (-0.001992 51.477846)', northeast: 'POINT (-0.001949 51.477873)').find_or_create_by(w3w: 'recent.suffice.chips')
plot.tiles.create_with(southwest: 'POINT (-0.001949 51.477819)', northeast: 'POINT (-0.001906 51.477846)').find_or_create_by(w3w: 'bravo.blocks.preoccupied')
plot.tiles.create_with(southwest: 'POINT (-0.001949 51.477846)', northeast: 'POINT (-0.001906 51.477873)').find_or_create_by(w3w: 'overnight.damp.serves')
plot.tiles.create_with(southwest: 'POINT (-0.001949 51.477873)', northeast: 'POINT (-0.001906 51.4779)').find_or_create_by(w3w: 'loads.descended.smile')

project.prices.create_with(amount_display: '£59 / year', title: 'Fifty Nine Quid Per Year', stripe_id: 'price_1MEXfWIUdRPXBaHSMA4bZddU').find_or_create_by(title: 'Annual Price')
project.prices.create_with(amount_display: '£5.99 / month', title: 'Five Ninety Nine Per Month', stripe_id: 'price_1MEXRZIUdRPXBaHS0TTmw632').find_or_create_by(title: 'Monthly Price')
