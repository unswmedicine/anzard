This document gives an overview of the system for future developers including those who may wish to reuse the application and/or contribute changes.

# Setting Up Your Development Environment
There are two documented methods for setting up a development environment:
- Local installation (Mac/CentOS)
- Docker installation

## Local Installation
This section describes how to install the ANZARD application within a local development environment.
Note: within the database configuration file `config/database.yml` the host of the development environment database needs to be changed from `db` to `localhost` for a local installation. The value `db` is only applicable for a Docker installation.

### Set up for Rails development
If you haven't already, you will need to set up your computer for Rails development. We highly recommend Mac or Linux over Windows as a development environment.

Install RVM (see https://rvm.io/rvm/install/ for the latest - steps below may change over time)
```
curl -L get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
```
Find the requirements (and follow the instructions):
```
rvm requirements
```
Install Ruby 2.4.0
```
rvm install ruby-1.9.3-p194
```
Install MySQL (Centos)
```
sudo yum install mysql-server mysql mysql-devel
sudo /etc/init.d/mysqld start
sudo /sbin/chkconfig mysqld on
```
Install MySQL (Mac)

We recommend using [Homebrew](http://mxcl.github.com/homebrew/) 
```
brew install mysql
```
then follow the instructions it provides

To start up the MySQL server you may have to execute in a terminal 
```
mysql.server start
```

### Set up ANZARD
Clone the repository
```
git clone git@github.com:IntersectAustralia/anzard.git
cd anzard  # accept .rvmrc if prompted, a new gemset will be created
```
Install required gems
```
bundle install
```

Set your MySQL root password (if you haven't already), and set up MySQL user for anzard
```
/usr/bin/mysqladmin -u root password 'some-pass'
mysql -uroot -psome-pass -e "CREATE USER 'anzard'@'localhost' IDENTIFIED BY 'anzard'; grant all on *.* to 'anzard'@'localhost' identified by 'anzard'; flush privileges;"
```
Create database, run seed and populate scripts (creates test data in local dev environment)
```
SKIP_PRELOAD_MODELS=skip rake db:setup db:populate
```

Start up the Delayed Job worker that processes batch files
```
rake jobs:work
```

Generate the user manual by running the following command
```
bundle exec jekyll build --source manual/ --destination public/user_manual/
```

Start up a local server, then have a look around at http://localhost:3000. Have a look at [the sample data populator script](https://github.com/IntersectAustralia/anzard/blob/master/lib/tasks/sample_data_populator.rb) for the list of users you can log in as
```
rails s
```

### Troubleshooting
If you run into and error installing the MySQL gem on OS X 64, e.g:
```
Installing mysql (2.8.1) 
Gem::Installer::ExtensionBuildError: ERROR: Failed to build gem native extension.

        /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/bin/ruby extconf.rb 
checking for mysql_ssl_set()... *** extconf.rb failed ***
Could not create Makefile due to some reason, probably lack of
necessary libraries and/or headers.  Check the mkmf.log file for more
details.  You may need configuration options.

Provided configuration options:
	--with-opt-dir
	--with-opt-include
	--without-opt-include=${opt-dir}/include
	--with-opt-lib
	--without-opt-lib=${opt-dir}/lib
	--with-make-prog
	--without-make-prog
	--srcdir=.
	--curdir
	--ruby=/Users/ilya/.rvm/rubies/ruby-1.9.3-p194/bin/ruby
	--with-mysql-config
	--without-mysql-config
/Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:381:in `try_do': The compiler failed to generate an executable file. (RuntimeError)
You have to install development tools first.
	from /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:461:in `try_link0'
	from /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:476:in `try_link'
	from /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:619:in `try_func'
	from /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:894:in `block in have_func'
	from /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:790:in `block in checking_for'
	from /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:284:in `block (2 levels) in postpone'
	from /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:254:in `open'
	from /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:284:in `block in postpone'
	from /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:254:in `open'
	from /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:280:in `postpone'
	from /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:789:in `checking_for'
	from /Users/ilya/.rvm/rubies/ruby-1.9.3-p194/lib/ruby/1.9.1/mkmf.rb:893:in `have_func'
	from extconf.rb:50:in `<main>'


Gem files will remain installed in /Users/ilya/.rvm/gems/ruby-1.9.3-p194@anzard/gems/mysql-2.8.1 for inspection.
Results logged to /Users/ilya/.rvm/gems/ruby-1.9.3-p194@anzard/gems/mysql-2.8.1/ext/mysql_api/gem_make.out

An error occurred while installing mysql (2.8.1), and Bundler cannot continue.
Make sure that `gem install mysql -v '2.8.1'` succeeds before bundling.
```
You will need to locate your mysql_config, e.g:

```
$ find / -name mysql_config 2>/dev/null
```

Open it in your favourite text editor and edit the lines around 120, changing:

```
cflags="-I$pkgincludedir  -Wall -Wno-null-conversion -Wno-unused-private-field -Os -g -fno-strict-aliasing -DDBUG_OFF " #note: end space!
cxxflags="-I$pkgincludedir  -Wall -Wno-null-conversion -Wno-unused-private-field -Os -g -fno-strict-aliasing -DDBUG_OFF " #note: end space!
```
To the following:
```
cflags="-I$pkgincludedir  -Wall -Os -g -fno-strict-aliasing -DDBUG_OFF " #note: end space!
cxxflags="-I$pkgincludedir  -Wall -Os -g -fno-strict-aliasing -DDBUG_OFF " #note: end space!
```
Running `bundle install` should now work.

## Docker Installation
- Clone the repository
- Change directory into the repo and run the command `docker-compose build` to build the containers
- Install RubyMine on your local environment
- Configure RubyMine Ruby SDK and Gems
   - Open the menu chain: RubyMine > Preferences > Language & Frameworks > Ruby SDK and Gems > New Remote Interpreter Path
   - Configure a Docker Compose Remote Ruby Interpreter using the service 'web'
- Create two run configurations for the project
   - Create a Docker Compose run configuration and give the config the path to the compose file
   - Create a Rails run configuration ensuring to use the environment 'development'
- Start the Docker Compose run configuration and then exec command `bash` on it to be able to execute project setup commands
   - Create the db & seed it: `SKIP_PRELOAD_MODELS=skip rake db:setup db:populate`
   - Generate the user manual : `bundle exec jekyll build --source manual/ --destination public/user_manual/`
- Stop the Docker Compose run configuration
- Start the Rails run configuration either in run mode or debug mode
   - If the debug mode does not start due to missing debug gem, try recreating the Ruby SDK and Gem configuration
- Visit the web application at localhost:3000
- Note: docker-compose exec needs to be used to start the rake task `rake jobs:work` in order to process any pending batch files.


# Key Components
* Ruby on Rails application (the application has been tested on Apache with Passenger (mod_rails), but can be run on your preferred deployment stack).
* MySQL database (other databases can be supported).
* File system (when batch files are uploaded, they are stored on the file system prior to being processed)
* Delayed job (this is a daemon process that runs in the background and processes incoming batch files - since the processing is quite intensive we don't do it in the web app).


# Navigating The Code
ANZARD is a Ruby on Rails (3.1) application so it follows the standard Rails application layout. Refer to the official Rails guides if you need an explanation of the directory layout.
Some key libraries we use are:
* Devise (authentication)
* Cancan (authorisation)
* JQuery
* HAML
* SASS
* Prawn (PDF generation)
* Will Paginate
* Paperclip (file upload)
* Delayed Job (batch file processing)

Refer to the Gemfile for a more complete list

# Understanding How To Specify The Questions
The questions are specified in a series of database tables. These can be imported from CSV files. The database tables store configuration such as the question code, display text, question type (date, numeric, radio button etc), validation rules (required, min/max ranges) and help text. They also store the set of options for radio button type questions, and a set of rules that apply across multiple questions.

Refer to the [Question Specification Guide](../question_specification_guide.md) for instructions on how to build the question specification CSV files.

# Automated Tests
ANZARD has a full suite of RSpec tests used to unit test our code. 

Some of the libraries we use for testing are:
* RSpec
* Factory girl

# Guide For Contributing
We welcome any contributions to the code base. Please send us a pull request with your changes. Any changes should have accompanying RSpec examples, and the full test suite should be passing.