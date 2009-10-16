Writing and Learning Communities
================================

The Writing and Learning Communities (WLC) system manages the workflow for
anonymous peer-reviewed assignments.

Installation
------------

The WLC system is a typical Ruby on Rails application.  We use Capistrano
to manage installation from the repository.  See config/deploy.rb for our
settings.  The only step we do by hand at the moment is changing the owner
of the public/stylesheets directory so that the Sass compiler can create
an updated styles.css file.

### Database Installation

To create the schema, run `rake db:setup`.  This will also install seed data.

### Required Libraries

The relative trust calculation requires the [Ruby-GSL][] library to do
the required matrix calculations.

[Ruby-GSL]: <http://rb-gsl.rubyforge.org/>
