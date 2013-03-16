# RER::Web

This web app is yet another variation on the "how can I possibly display the
timetable for the 6 next trains in any way I can imagine" theme.  Only this
time, it tries to be classy.  Its aim is to be compatible with small (mobile)
screens, medium (tablet/desktop) screens and large screens (TVs).

See it in action at (http://x0r.fr/rer)[http://x0r.fr/rer].

I know the SNCF's website does the same thing, but let's face it, this
interface is sexier.

# Installing

Initialize the station database as follows:

	% sqlite3 gares.db < db.sql

Then, deploy it as you would any Perl::Dancer application.
