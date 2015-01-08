# cheetahmail

A command-line interface to performing some common tasks with Experian's
CheetahMail ESP, since it lacks an API and is generally horrible to use.

This is very much a work in progress.

# Download a segment

To choose from a menu of available segments (interactive mode):

	$ cheetahmail segment -u username -p password

To specify a segment:

	$ cheetahmail segment -u username -p password --segment 'Optins'

Outputs the filename of the saved segment.

# Listing mailings

List the last 50 mailings:

	$ cheetahmail mailings -u username -p password

# Mailing stats

Output a report for a given mailing:

	$ cheetahmail report -u username -p password --mailing 'The subject line of the mailing'

Output the stats as JSON:

	$ cheetahmail report -u username -p password --mailing 'The subject line of the mailing' --json
