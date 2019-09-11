{
	blogTitle => 'My Blog',								# Blog title
	adminPass => 'woofwoof',								# Admin password for adding entries
	smiliesFolder => 'app/media/smilies',								# Path to smilies, if you dont want smilies, just, dont upload that folder
	smiliesFolderName => 'smilies',												# Smilies Folder Name, you should NOT change this...
	postsDatabaseFolder => '/root/http/blog/posts',							# Name of the folder where entries will be saved. If you cant create entries with this path, try /home/www/user/posts
	commentsDatabaseFolder => '/root/http/blog/comments',						# Name of the folder where entries will be saved. If you cant create entries with this path, try /home/www/user/posts
	dbFilesExtension => 'ppl',								# Extension of the files used as databases
	currentStyleFolder => 'app',								# Styles folder (. => in the same path as ths file)
	entriesPerPage => 10,										# For pagination... How many entries will be displayed per page?
	maxPagesDisplayed => 5,									# Maximum number of pages displayed at the bottom
	metaRevisitAfter => 1,									# This is for search Engines... How often will they check for updates, in days
	metaDescription => 'My Blog',			# Also for search engines
	metaKeywords => 'blog, posts, pplog, pBlog',					# Also for search engines...
	textAreaCols => 50,										# Cols of the textarea to add and edit entries
	textAreaRows => 10,										# Rows of the textarea to add and edit entries
	config_ipBan => {202.325.35.145, 165.265.26.65},				# 2 random IPS, sorry if it is yours... Just edit this, separate ips with spaces
	bannedMessage => 'Sorry, you have been banned.',			# This message will appear when an user is banned from the blog
	allowComments => 1,										# Allow comments
	bbCodeOnCommentaries => 1,								# Allow BBCODE on commentaries									(0 => No, 1 => Yes)
	commentsMaxLenght => 2000,								# Comment maximum characters
	commentsSecurityCode => 1,								# Allow security code for comments 								(0 => No, 1 => Yes)
	config_commentsForbiddenAuthors => {admin, administrator},		# These are the usernames that normal users cant use, if you use one of these, it will ask for password
	commentsDescending => 0,									# Showing NOT in descending order, this will show oldest first	(0 => No, 1 => Yes)
	searchMinLength => 4,									# Minimum length of the keyword to search, this is for avoiding seeking words like "and", "or", "a", etc
	redditAllowed => 0,										# Allow the reddit option, to share your posts					(0 => No, 1 => Yes)
	menuEntriesLimit => 10,									# Limits of entries to show in the menu
	config_menuLinks => {'http://puppylinux.com/,Puppy Home', 'http://murga-linux.com/puppy//,Puppy Forums'},										# Links to be displayed at the menu
	menuShowLinks => 1,										# Show links at the menu?										(0 => No, 1 => Yes)
	menuLinksHeader => 'Links',								# This is the header before the links appear, you can change it as you wish, normal is Links or Blogroll
	allowCustomHTML => 0,									# Want to add some code? Edit here								(0 => No, 1 => Yes)
	customHTML => '<h1>Hello</h1> This is custom HTML',		# HTML here
	showHits => 1,											# Want to show how many users are browsing your blog?			(0 => No, 1 => Yes)
	sendMailWithNewComment => 0,								# Receive a mail when someone posts a comment					(0 => No, 1 => Yes) It works only if you host allows sendmail
	sendMailWithNewCommentMail => 'root@localhost',		# Email adress to send mail if allowed
	showUsersOnline => 1,									# Wanna show how many users are browsing your site?				(0 => No, 1 => Yes)
	usersOnlineTimeout => 120,								# How long is an user considered online? In seconds
	gmt => -5,												# Your GMT, -3 => Buenos Aires
	showLatestComments => 1,									# Show latest comments on the menu
	showLatestCommentsLimit => 10,							# Show 10 latest comments
	allowBBcodeButtonsOnComments => 1,						# Allow BBCODE Buttons on Comments Form
	commentsPerPage => 20,									# How many comments will be shown per page
	showGmtOnFooter => 1,									# Display GMT on footer
	securityQuestionOnComments => 1,							# Allow the option to display a question which users have to answer in order to post comments
	commentsSecurityQuestion => 'A tasty snack?',	# You shall change it, choose a question all your users will know
	commentsSecurityAnswer => 'apple',						# Answer of the security question. The comparison will be CaSe InSeNsItIvE
	randomString => 'zasdfasdflkjasdifasdfsadgf',			# This is for password encryption... Edit if you want
	entriesOnRSS => 20,									# 0 => ALL ENTRIES, if you want a limit, change this
	useHtmlOnEntries => 0,									# Allow HTML on entries when making a new post (THIS WILL DISALLOW BBCODE!!)
	useWYSIWYG => 0,											# You must allow HTML on entries for this to work // Note, WYSIWYG wont allow smilies
	onlyNumbersOnCAPTCHA => 1,								# Use only numbers on CAPTCHA
	CAPTCHALength => 8										# Just to make different codes
}