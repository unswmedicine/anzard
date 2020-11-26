#!/bin/bash
RAILS_ENV=$1 docker-compose -f docker-compose.yml -f docker-compose.testing.yml up db web
