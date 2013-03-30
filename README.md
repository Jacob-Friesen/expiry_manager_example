Description:
============
This is a small Ruby on Rails 3.2 application demonstrating what the expiry manager code does. It's root page uses fragment caches and contains links to expire caches, there is no other pages. Also for simplicity there is no database. The expiry manager's purpose is to provide a centralized location for fragment expiry as opposed to fragment expiries being scattered throughout the application.

Installation:
=============
Steps on Unix based systems (Windows will be very similar):

1. **git clone:** git clone https://github.com/Jacob-Friesen/expiry_manager_example.git
2. **Install gems:** cd expiry\_manager\_example && bundle install
3. **run it**: rails s


Important Locations:
====================

 * **lib/expiry\_manager:** The location of the expiry manager files 
  * **expiry\_manager.rb:** Detects when to expire fragments and what fragments to expire using expiry\_mapping.rb
  * **expiry\_mapping.rb:** Defines mapping of actions to fragment expirations, supports custom actions
  * **expiry\_manager_spec.rb:** Rspec based tests for expiry\_manager.rb, does *not* need expiry\_mapping.rb
 * **app/views/part1/index.html.rb:** HTML generating file that contains the caches
 * **app/controllers/part1\_controller.rb:** Actions that the main page uses
 * **app/controllers/application\_controller.rb:** Where the expiry manager is hooked in (via a before\_filter)
