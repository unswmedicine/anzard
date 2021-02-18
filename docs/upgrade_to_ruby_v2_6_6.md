## update the rbenv and ruby-build
cd ~/.rbenv
git pull
git checkout v1.1.2
cd ~/.rbenv/plugins/ruby-build
git pull
git checkout v20201210

## install ruby 2.6.6
cd
rbenv install -v -s 2.6.6
rbenv versions

## install bundler 2.1.4
cd ~/anzard
rbenv local 2.6.6
gem install bundler -v 2.1.4
bundle install

## install apache passenger 6.0.7 module
cd ~/.rbenv/versions/2.6.6/lib/ruby/gems/2.6.0/gems/passenger-6.0.7/
./bin/passenger-install-apache2-module --auto --languages ruby
sudo cp /etc/httpd/conf.d/passenger.conf /etc/httpd/conf.d/passenger.conf.bak

## update passenger apache conf
vim /etc/httpd/conf.d/passenger.conf

## update the anzard.conf
vim /etc/httpd/conf.d/anznn.conf
```
        PassengerRuby /home/devel/.rbenv/versions/2.6.6/bin/ruby

```
