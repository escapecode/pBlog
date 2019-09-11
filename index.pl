#!/usr/bin/perl -U

#####################################################
# 	pBlog						#
#	The idea of this blog, is a very simple yet		#
#	powerful blog. Enjoy.							#
#													#
#	Coded by Federico Ramírez (fedekun)				#
#	fedekiller@gmail.com							#
#													#
#	pBlog uses the GNU Public Licence v3			#
#	http://www.opensource.org/licenses/gpl-3.0.html	#
#													#
#	Powered by YAGNI (You Ain't Gonna Need It)		#
#	YAGNI: Only add things, when you actually 		#
#	need them, not because you think you will.		#
#													#
#	Version: 1.1b									#
#####################################################

#BK 8jul09 patch from fedekun, blog writes zero-byte file if leave title off a post.
#BK 8jul09 removed this from all submit forms, doesn't work with opera and ie...
# onclick="javascript:this.disabled=true"
#120513 IWill: solution for the day 31 bug.
#120513 L18L: replaced iso8858-1 with UTF-8.

use CGI::Carp qw/fatalsToBrowser/;	# This is optional
use CGI':all';
use POSIX qw(ceil floor);
use strict;							# This is also optional

my $config=do("./app/config.pl");
die "Error parsing config file: $@" if $@;
die "Error reading config file: $!" unless defined $config;
$config;

# Basic Functions
sub r
{
	escapeHTML(param($_[0]));
}

sub basic_r
{
	param($_[0]);
}

sub bbcode
{
	$_ = $_[0];
	s/\n/<br \/>/gi;
	s/\[b\](.+?)\[\/b\]/<b>$1<\/b>/gi;
	s/\[i\](.+?)\[\/i\]/<i>$1<\/i>/gi;
	s/\[u\](.+?)\[\/u\]/<u>$1<\/u>/gi;
	s/\[\*\](.+?)\[\/\*\]/<li>$1<\/li>/gi;
	s/\[center\](.+?)\[\/center\]/<center>$1<\/center>/gi;
	s/\[url\](.+?)\[\/url\]/<a href=$1 target=_blank>$1<\/a>/gi;
	s/\[url=(.+?)\](.+?)\[\/url\]/<a href=$1 target=_blank>$2<\/a>/gi;
	s/\[img\](.+?)\[\/img\]/<img src=$1 \/>/gi;
	s/\[code\](.+?)\[\/code\]/<div class=code><pre>$1<\/pre><\/div>/gi;
	s/\[quote\](.+?)\[\/quote\]/<div class=quote>$1<\/div>/gi;
	if(-d "$config->{smiliesFolder}")
	{
		my @smilies;
		my $s;
		if(opendir(DH, $config->{smiliesFolder}))
		{
			@smilies = grep {/gif/ || /jpg/ || /png/;} readdir(DH);
		}
		foreach $s(@smilies)
		{
			my @i = split(/\./, $s);
			s/\:$i[0]\:/<img src=$config->{smiliesFolderName}\/$i[0].$i[1] \/>/gi;
		}
	}
	return $_;
}

sub bbdecode
{
	$_ = $_[0];
	s/\n//;
	s/<br \/>//gi;
	s/\<b\>(.+?)\<\/b\>/\[b\]$1\[\/b\]/gi;
	s/\<i\>(.+?)\<\/i\>/\[i\]$1\[\/i\]/gi;
	s/\<u\>(.+?)\<\/u\>/\[u\]$1\[\/u\]/gi;
	s/\<li\>(.+?)\<\/li\>/\[\*\]$1\[\/\*\]/gi;
	s/\<center\>(.+?)\<\/center\>/\[center\]$1\[\/center\]/gi;
	s/\<a href=(.+?)\ target=_blank\>(.+?)\<\/a\>/\[url=$1\]$2\[\/url\]/gi;
	s/\<img src=(.+?) \/>/\[img\]$1\[\/img\]/gi;
	s/\<div class=code\>\<pre\>(.+?)\<\/pre\>\<\/div\>/\[code\]$1\[\/code\]/gi;
	s/\<div class=quote\>(.+?)\<\/div\>/\[quote\]$1\[\/quote\]/gi;
	return $_;
}

sub txt2html
{
	$_ = $_[0];
	s/\n/<br \/>/gi;
	return $_;
}

sub getdate
{
	my $gmt = $_[0];
	my $date = gmtime;
	my @dat = split(' ', $date);
	my @time = split(':',$dat[3]);

	my $day = $dat[2];
	my $hour = $time[0]+$gmt;

	if($hour < 1)
	{
		$hour = floor($hour+24);
		$day--;
	}

# 120513 IWill: solution for the day 31 bug...
#	elsif($hour > 24)
#	{
#		$hour = floor(((24-$hour)*-1)+1);
#		$day++;
#	}
	elsif($hour > 24)
	{
		$hour = floor(((25-$hour)*-1)+1);
		$day++;
	}
	if($hour == 24)
	{
		$hour = 0;
		$day++;
	}

	return $day.' '.$dat[1].' '.$dat[4].', '.$hour.':'.$time[1];
}

sub array_unique
{
	my %seen = ();
	@_ = grep { ! $seen{ $_ }++ } @_;
}

sub getFiles			# This function returns all files from the db folder
{
	if(!(opendir(DH, $_[0])))
	{
		mkdir($config->{postsDatabaseFolder}, 0755);
	}

	my @entriesFiles = (); 		# This one has all files names
	my @entries = (); 			# This one has the content of all files not splitted

	foreach(readdir DH)
	{
		unless($_ eq '.' or $_ eq '..' or (!($_ =~ /$config->{dbFilesExtension}$/)))
		{
			push(@entriesFiles, $_);
		}
	}

	@entriesFiles = sort{$b <=> $a}(@entriesFiles);		# Here I order the array in descending order so i show Newest First

	foreach(@entriesFiles)
	{
		my $tempContent = '';
		open(FILE, "<".$_[0]."/$_");
		while(<FILE>)
		{
			$tempContent.=$_;
		}
		close FILE;
		push(@entries, $tempContent);
	}
	return @entries;
}

sub getCategories		# This function is to get the categories not repeated in one array
{
	my @categories = ('General');
	my @tempCategories = ();
	if(-d "$config->{postsDatabaseFolder}")
	{
		my @entries = getFiles($config->{postsDatabaseFolder});
		foreach(@entries)
		{
			my @finalEntries = split(/"/, $_);
			push(@tempCategories, $finalEntries[3]);
		}
		@categories = array_unique(@tempCategories);
	}
	return @categories;
}

sub getPages
{
	open (FILE, "<$config->{postsDatabaseFolder}/pages.$config->{dbFilesExtension}.page");
	my $pagesContent;
	while(<FILE>)
	{
		$pagesContent.=$_;
	}
	close FILE;

	my @pages = split(/-/, $pagesContent);
}

sub getComments
{
	open(FILE, "<$config->{commentsDatabaseFolder}/latest.$config->{dbFilesExtension}");
	my $content;
	while(<FILE>)
	{
		$content.=$_;
	}
	close(FILE);

	my @comments = split(/'/, $content);
	@comments = reverse(@comments);			# We want newer first right?
}

if(r('do') eq 'RSS')
{
	my @baseUrl = split(/\?/, 'http://'.$ENV{'HTTP_HOST'}.$ENV{'REQUEST_URI'});
	my $base = $baseUrl[0];
	my @entries = getFiles($config->{postsDatabaseFolder});
	my $limit;

	print header('text/xml'),'<?xml version="1.0" encoding="UTF-8"?>
	<rss version="2.0">
	<channel>
	<title>'.$config->{blogTitle}.'</title>
	<description>'.$config->{metaDescription}.'</description>
	<link>http://'.$ENV{'HTTP_HOST'}.substr($ENV{'REQUEST_URI'},0,length($ENV{'REQUEST_URI'})-7).'</link>';

	if($config->{entriesOnRSS} == 0)
	{
		$limit = scalar(@entries);
	}
	else
	{
		$limit = $config->{entriesOnRSS};
	}

	for(my $i = 0; $i < $limit; $i++)
	{
		my @finalEntries = split(/"/, $entries[$i]);
		my $content = $finalEntries[1];
		$content =~ s/\</&lt;/gi;
		$content =~ s/\>/&gt;/gi;
		print '<item>
		<link>'.$base.'?viewDetailed='.$finalEntries[4].'</link>
		<title>'.$finalEntries[0].'</title>
		<category>'.$finalEntries[3].'</category>
		<description>'.$content.'</description>
		</item>';
	}

	print '</channel>
	</rss>';
}
else
{
print header(-charset => qw(utf-8)), '<!DOCTYPE HTML PUBLIC -//W3C//DTD HTML 4.01 Transitional//EN
http://www.w3.org/TR/html4/loose.dtd>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="Name" content="'.$config->{blogTitle}.'" />
<meta name="Revisit-After" content="'.$config->{metaRevisitAfter}.'" />
<meta name="Keywords" content="'.$config->{metaKeywords}.'" />
<meta name="Description" content="'.$config->{metaDescription}.'" />
<title>'.$config->{blogTitle}.'</title>
<script language="javascript" type="text/javascript">
// FUNCTION BY SMF FORUMS http://www.simplemachines.org
function surroundText(text1, text2, textarea)
{
	// Can a text range be created?
	if (typeof(textarea.caretPos) != "undefined" && textarea.createTextRange)
	{
		var caretPos = textarea.caretPos, temp_length = caretPos.text.length;

		caretPos.text = caretPos.text.charAt(caretPos.text.length - 1) == \' \' ? text1 + caretPos.text + text2 + \' \' : text1 + caretPos.text + text2;

		if (temp_length == 0)
		{
			caretPos.moveStart("character", -text2.length);
			caretPos.moveEnd("character", -text2.length);
			caretPos.select();
		}
		else
			textarea.focus(caretPos);
	}
	// Mozilla text range wrap.
	else if (typeof(textarea.selectionStart) != "undefined")
	{
		var begin = textarea.value.substr(0, textarea.selectionStart);
		var selection = textarea.value.substr(textarea.selectionStart, textarea.selectionEnd - textarea.selectionStart);
		var end = textarea.value.substr(textarea.selectionEnd);
		var newCursorPos = textarea.selectionStart;
		var scrollPos = textarea.scrollTop;

		textarea.value = begin + text1 + selection + text2 + end;

		if (textarea.setSelectionRange)
		{
			if (selection.length == 0)
				textarea.setSelectionRange(newCursorPos + text1.length, newCursorPos + text1.length);
			else
				textarea.setSelectionRange(newCursorPos, newCursorPos + text1.length + selection.length + text2.length);
			textarea.focus();
		}
		textarea.scrollTop = scrollPos;
	}
	// Just put them on the end, then.
	else
	{
		textarea.value += text1 + text2;
		textarea.focus(textarea.value.length - 1);
	}
}
</script>
<link href='.$config->{currentStyleFolder}.'/style.css rel=stylesheet type=text/css>
</head>
<body>
<div id=all>
<div id=top>
	<img src="app/media/logo.png" style="position: absolute; left: 10px;"/><h2><center>'.$config->{metaDescription}.'</center></h2>
	 <a href=?page=1 style="padding-left: 200px;">All Posts</a> - <a href="about_me.html">About Me</a> - <a href="help.html">Help</a>
	<div class="topbar">
		<form accept-charset="UTF-8"   name="form1" method="post">
			<input type="text" name="keyword" placeholder="Search terms">
			<input type="hidden" name="do" value="search">
			<input type="submit" name="Submit" value="Search"><br />
			By Title <input name="by" type="radio" value="0" checked> By Content <input name="by" type="radio" value="1">
		</form>
		<a href="?do=newEntry" style="right: 10px;"><button>Add Post</button></a> &nbsp;';

#if(($config->{showUsersOnline} == 1) || ($config->{showHits} == 1))
#{
	#print '<hr />
	#<h1><center>Stats</center></h1>';
#}
	print '<span style="font-size: .8em;">';
if($config->{showUsersOnline} == 1)
{
	# Show users online

	my $remote = $ENV{"REMOTE_ADDR"};
	my $timestamp = time();
	my $timeout = ($timestamp-$config->{usersOnlineTimeout});

	if((-s "$config->{postsDatabaseFolder}/online.$config->{dbFilesExtension}.uo") > (1024*5))		# If its bigger than 0.5 MB, truncate the file and start again
	{
		open(FILE, "+>$config->{postsDatabaseFolder}/online.$config->{dbFilesExtension}.uo");
	}
	else
	{
		open(FILE, ">>$config->{postsDatabaseFolder}/online.$config->{dbFilesExtension}.uo");
	}

	print FILE $remote."||".$timestamp."\n";
	close FILE;
	my @online_array = ();
	my $content;
	open(FILE, "<$config->{postsDatabaseFolder}/online.$config->{dbFilesExtension}.uo");
	while(<FILE>)
	{
		$content.=$_;
	}
	close FILE;

	my @l = split(/\n/, $content);
	foreach(@l)
	{
		my @f = split(/\|\|/, $_);
		my $ip = $f[0];
		my $time = $f[1];
		if($time >= $timeout)
		{
			push(@online_array, $ip);
		}
	}
	@online_array = array_unique(@online_array);
	print ' &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Online: <b>'.scalar(@online_array) . '</b><br />';
}

if($config->{showHits} == 1)
{
	# Display Hits

	# Check hits
	open(FILE, "<$config->{postsDatabaseFolder}/hits.$config->{dbFilesExtension}.hits");
	my $content;
	while(<FILE>)
	{
		$content.=$_;
	}
	close FILE;

	# Add hits
	open(FILE, ">$config->{postsDatabaseFolder}/hits.$config->{dbFilesExtension}.hits");
	print FILE ++$content;
	close FILE;

	print ' &nbsp; Page Hits: <b>'.$content . '</b>';
}

	print '</span></div>
</div>
<div id=menu>
<hr />';
#print '<h1>Latest Entries</h1>';

#my @entriesOnMenu = getFiles($config->{postsDatabaseFolder});
#my $i = 0;
#foreach(@entriesOnMenu)
#{
	#if($i <= $config->{menuEntriesLimit})
	#{
		#my @entry = split(/"/, $_);
		#my $title = $entry[0];
		#my $fileName = $entry[4];
		#my @pages = getPages();
		#my $do = 1;
		#foreach(@pages)
		#{
			#if($_ == $entry[4])
			#{
				#$do = 0;
				#last;
			#}
		#}

		#if($do == 1)
		#{
			#print '<a href="?viewDetailed='.$fileName.'">'.$title.'</a>';
		#}

		#$i++;
	#}
#}

# Display Pages
my @pages = getPages();

if(scalar(@pages) > 0)
{
	print '<h1>Headlines</h1>';
}

foreach(@pages)
{
	my $fileName = $_;
	my $content;
	open(FILE, "<$config->{postsDatabaseFolder}/$fileName.$config->{dbFilesExtension}");
	while(<FILE>)
	{
		$content.=$_;
	}
	close FILE;
	my @data = split(/"/, $content);
	my $title = $data[0];
	print '<a href="?viewDetailed='.$fileName.'">'.$title.'</a>';
}

print '<h1><center>Post Categories</center></h1>';			# Show Categories on Menu	THIS IS THE MENU SECTION
my @categories = sort(getCategories());
foreach(@categories)
{
	print '<a href="?viewCat='.$_.'">'.$_.'</a>';
}
print 'No categories yet.' if scalar(@categories) == 0;
if($config->{showLatestComments} == 1)
{
	# Latest comments on the menu

	my @comments = getComments();

	if(scalar(@comments) > 0)
	{
		print '<hr /><h1><center>Latest Comments</center></h1>';
	}

	my $i = 0;

	foreach(@comments)
	{
		if($i <= $config->{showLatestCommentsLimit})
		{
			my @entry = split(/"/, $_);
			print '<a href="?viewDetailed='.$entry[4].'" title="Posted by '.$entry[1].'">'.$entry[0].'</a>';
			$i++;
		}
	}
	print '<br /><a style="float: right; font-size : .8em; font-weight : bold;" href="?do=listComments">All Comments</a><br />'
		if scalar(@comments) > 0;
}

if($config->{allowCustomHTML} == 1)
{
	# Display Custom HTML Defined on the configuration

	print $config->{customHTML};
}
print '<hr />
<a href=?do=archive style="float: left;">Archived Posts</a>
<a href="?do=RSS" style="float: right;"><img src="app/media/rss.svg" alt="RSS feed link" width="25px;" /></a>
<br style="clear: both;" />
<hr />';


if($config->{redditAllowed} == 1)
{
	# Show the Reddit Button if allowed

	print '<h1>Share</h1>
	<a target="_blank" href="http://reddit.com/submit?url=http://'.$ENV{'HTTP_HOST'}.$ENV{'REQUEST_URI'}.'">
	Post Current to Reddit <!-- <img border="0" src="app/media/reddit.gif" />--></a>';
}

if($config->{menuShowLinks} == 1)
{
	# Show Some Links Defined on the Configuration

	if($config->{menuLinks} > 0)
	{
		print '<h1>'.$config->{menuLinksHeader}.'</h1>';
		foreach($config->{menuLinks})
		{
			my @link = split(/,/, $_);
			print '<a href="'.$link[0].'">'.$link[1].'</a>';
		}
	}
}


print '</div><div id=content>';

foreach($config->{ipBan})
{
	if($ENV{'REMOTE_ADDR'} == $_)
	{
		die($config->{bannedMessage});
	}
}

# Start with GETS and POSTS		CONTENT SECTION

if(r('do') eq 'newEntry')
{
	# Add Secure (This page will appear before the add one)

	print '<h1>Adding Post...</h1>
	<form accept-charset="UTF-8"   name="form1" method="post">
	<table>
	<td>Password:</td>
	<td><input name="pass" type="password" id="pass">
	<input name="process" type="hidden" id="process" value="doNewEntry"></td>
	</tr>
	<tr>
	<td>&nbsp;</td>
	<td><input type="submit" name="Submit" value="Add New Post"></td>
	</tr>
	</table>
	</form>';
}
elsif(r('process') eq 'doNewEntry')
{
	# Blog Add New Post Form

	my $pass = r('pass');
	if($pass eq $config->{adminPass})
	{
		my @categories = getCategories();
		print '<h1>Making New Post</h1>
		<form accept-charset="UTF-8"   action="" name="submitform" method="post">
		<table>
		<tr>
		<td>Title</td>
		<td><input name=title type=text id=title></td>
		</tr>';
		if($config->{useHtmlOnEntries} == 0)
		{
			print '<tr>
				<td>&nbsp;</td>
				<td><input type="button" style="width:50px;font-weight:bold;" onClick="surroundText(\'[b]\', \'[/b]\', document.forms.submitform.content); return false;" value="b" />
				<input type="button" style="width:50px;font-style:italic;" onClick="surroundText(\'[i]\', \'[/i]\', document.forms.submitform.content); return false;" value="i" />
				<input type="button" style="width:50px;text-decoration:underline;" onClick="surroundText(\'[u]\', \'[/u]\', document.forms.submitform.content); return false;" value="u" />
				<input type="button" style="width:50px;" onClick="surroundText(\'[url]\', \'[/url]\', document.forms.submitform.content); return false;" value="url" />
				<input type="button" style="width:50px;" onClick="surroundText(\'[img]\', \'[/img]\', document.forms.submitform.content); return false;" value="img" />
				<input type="button" style="width:50px;" onClick="surroundText(\'[code]\', \'[/code]\', document.forms.submitform.content); return false;" value="code" /></td>
			</tr>';
		print '<tr><td>Content<br />(You can use BBCODE)<br />
			<!-- <a href="?do=showSmilies" target="_blank">Show Smilies</a><br />-->
			<img src="smilies/worried.gif">:worried:<br />
			<img src="smilies/n_n.png">:n_n:<br />
			<img src="smilies/happy.gif">:happy:<br />
			<img src="smilies/doh.gif">:doh:<br />
			<img src="smilies/cry.png">:cry:<br />
			<img src="smilies/cool.gif">:cool:
		</td>';
		}
		else
		{
			print '<script src="app/nicEdit.js" type="text/javascript"></script>
			<script type="text/javascript">bkLib.onDomLoaded(nicEditors.allTextAreas);</script>' if($config->{useWYSIWYG} == 1);
			print '<tr><td>';
		}
		print '<td><textarea name="content" cols='.$config->{textAreaCols}.'" rows="'.$config->{textAreaRows}.'" ';
		print ' style="height: 400px; width: 400px;" ' if( ($config->{useWYSIWYG} == 1) && ($config->{useHtmlOnEntries} == 1) );
		print ' id="content"></textarea></td></tr><tr><td>Category<br />(Available: ';
		my $i = 1;
		foreach(@categories)
		{
			if($i < scalar(@categories))	# Here we display a comma between categories so is easier to undesrtand
			{
				print $_.', ';
			}
			else
			{
				print $_;
			}
			$i++;
		}
		print ')</td>
		<td><input name="category" type="text" id="category"></td>
		</tr>
		<tr>
		<td>Make Headline not Post<a href="javascript:alert(\'Add to the main menu HEADLINE section, but do not make visibile when listing posts (however can be found by searching)\')">(?)</a></td>
		<td><input type="checkbox" name="isPage" value="1"></td>
		</tr>
		<tr>
		<td>Admin Password</td>
		<td><input name="pass" type="password" id="pass">
		<input name="process" type="hidden" id="process" value="newEntry"></td>
		</tr>
		<tr>
		<td>&nbsp;</td>
		<td><input type="submit" name="Submit" value="Add Post"></td>
		</tr>
		</table>
		</form>';
	}
	else
	{
		print 'Wrong Password';
	}
}
elsif(r('process') eq 'newEntry')
{
	# Blog Add New Post Page

	my $pass = r('pass');


        #BK 7JUL09 patch from fedekun, fix post with no title that caused zero-byte message...
        my $title = r('title');
        my $content = '';
        if($config->{useHtmlOnEntries} == 0)
        {
            $content = bbcode(r('content'));
        }
        else
        {
            $content = basic_r('content');
        }
        my $category = r('category');
        my $isPage = r('isPage');

        if($title eq '' || $content eq '' || $category eq '')
        {
            die("All fields are neccesary!");
        }

        if($pass eq $config->{adminPass})
        {
         my @files = getFiles($config->{postsDatabaseFolder});
         my @lastOne = split(/"/, $files[0]);
         my $i = 0;

         if($lastOne[4] eq '')
         {
            $i = sprintf("%05d",0);
         }
         else
         {
            $i = sprintf("%05d",$lastOne[4]+1);
         }

         unless(-d "$config->{postsDatabaseFolder}")
         {
            print 'The folder '.$config->{postsDatabaseFolder}.' does not exists...Creating it...<br />';
            mkdir($config->{postsDatabaseFolder}, 0755);
         }

         open(FILE, ">$config->{postsDatabaseFolder}/$i.$config->{dbFilesExtension}");

         my $date = getdate($config->{gmt});
         print FILE $title.'"'.$content.'"'.$date.'"'.$category.'"'.$i;    # 0: Title, 1: Content, 2: Date, 3: Category, 4: FileName
         print 'Your post <b>'.$title.'</b> has been saved. <a href="?page=1">Go to Index</a>';
         close FILE;

         if($isPage == 1)
         {
            open(FILE, ">>$config->{postsDatabaseFolder}/pages.$config->{dbFilesExtension}.page");
            print FILE $i.'-';
            close FILE;
         }
        }
	#BK 7JUL09 patch end.
	else
	{
		print 'Wrong password!';
	}
}
elsif(r('viewCat') ne '')
{
	# Blog Category Display

	my $cat = r('viewCat');
	my @entries = getFiles($config->{postsDatabaseFolder});
	my @thisCategoryEntries = ();
	my @categories = ();
	foreach(@entries)
	{
		my @split = split(/"/, $_);											# [0] = Title	[1] = Content	[2] = Date	[3] = Category
		if($split[3] eq $cat)
		{
			push(@thisCategoryEntries, $_);
		}
	}

	# Pagination - This is the so called Pagination
	my $page = r('p');																# The current page
	if($page eq ''){ $page = 1; }													# Makes page 1 the default page
	my $totalPages = ceil((scalar(@thisCategoryEntries))/$config->{entriesPerPage});	# How many pages will be?
	# What part of the array should i show in the page?
	my $arrayEnd = ($config->{entriesPerPage}*$page);									# The array will start from this number
	my $arrayStart = $arrayEnd-($config->{entriesPerPage}-1);							# And loop till this number
	# As arrays start from 0, i will lower 1 to these values
	$arrayEnd--;
	$arrayStart--;

	my $i = $arrayStart;															# Start Looping...
	while($i<=$arrayEnd)
	{
		unless($thisCategoryEntries[$i] eq '')
		{
			my @finalEntries = split(/"/, $thisCategoryEntries[$i]);
			my @pages = getPages();
			my $do = 1;
			foreach(@pages)
			{
				if($_ == $finalEntries[4])
				{
					$do = 0;
					last;
				}
			}

			if($do == 1)
			{
				print '<div class="post">
					<i style="float : right; font-size : .8em;">'.$finalEntries[2] . '</i>
					<h1><a href="?viewDetailed='.$finalEntries[4].'">'.$finalEntries[0].'</a></h1>
					<div class="entry">'
						.$finalEntries[1].'
					</div>
					<br />
					<div class="postinfo">
						<br /><div class="right"><a href="?viewDetailed='.$finalEntries[4].'">Comments</a><!-- - <a href="?edit='.$finalEntries[4].'">Edit</a> - <a href="?delete='.$finalEntries[4].'">Delete</a>--></div></i>
					</div>
				</div>';
			}
		}
		$i++;
	}
	# Now i will display the pages
	if($totalPages >= 1)
	{
		print '<center> Pages: ';
	}
	else
	{
		print '<center> No posts under this category.';
	}

	my $startPage = $page == 1 ? 1 : ($page-1);
	my $displayed = 0;
	for(my $i = $startPage; $i <= (($page-1)+$config->{maxPagesDisplayed}); $i++)
	{
		if($i <= $totalPages)
		{
			if($page != $i)
			{
				if($i == (($page-1)+$config->{maxPagesDisplayed}) && (($page-1)+$config->{maxPagesDisplayed}) < $totalPages)
				{
					print '<a href="?viewCat='.$cat.'&p='.$i.'">['.$i.']</a> ...';
				}
				elsif($startPage > 1 && $displayed == 0)
				{
					print '... <a href="?viewCat='.$cat.'&p='.$i.'">['.$i.']</a> ';
					$displayed = 1;
				}
				else
				{
					print '<a href="?viewCat='.$cat.'&p='.$i.'">['.$i.']</a> ';
				}
			}
			else
			{
				print '['.$i.'] ';
			}
		}
	}
	print '</center>';
}
elsif(r('edit') ne '')
{
	# Edit Secure (This page will appear before the edit one)

	my $fileName = r('edit');
	print '<h1>Editing Post...</h1>
	<form accept-charset="UTF-8"   name="form1" method="post">
	<table>
		<td>Admin Password</td>
		<td><input name="pass" type="password" id="pass">
		<input name="process" type="hidden" id="process" value="editSecured">
		<input name="fileName" type="hidden" id="fileName" value="'.$fileName.'"></td>
		</tr>
		<tr>
		<td>&nbsp;</td>
		<td><input type="submit" name="Submit" value="Edit Post"></td>
		</tr>
	</table>
	</form>';
}
elsif(r('process') eq 'editSecured')
{
	# Edit Post Page

	my $pass = r('pass');

	if($pass eq $config->{adminPass})
	{
		my $id = r('fileName');
		my $tempContent = '';
		open(FILE, "<$config->{postsDatabaseFolder}/$id.$config->{dbFilesExtension}");
		while(<FILE>)
		{
			$tempContent.=$_;
		}
		close FILE;
		my @entry = split(/"/, $tempContent);
		my $fileName = $entry[4];
		my $title = $entry[0];
		my $content = $entry[1];
		my $category = $entry[3];
		print '<h1>Editing Entry...</h1>
		<form accept-charset="UTF-8"   action="" name="submitform" method="post">
		<table>
		<tr>
		<td>Title</td>
		<td><input name=title type=text id=title value="'.$title.'"></td>
		</tr>';
		if($config->{useHtmlOnEntries} == 0)
		{
			print '<tr>
			<td>&nbsp;</td>
			<td><input type="button" style="width:50px;font-weight:bold;" onClick="surroundText(\'[b]\', \'[/b]\', document.forms.submitform.content); return false;" value="b" />
			<input type="button" style="width:50px;font-style:italic;" onClick="surroundText(\'[i]\', \'[/i]\', document.forms.submitform.content); return false;" value="i" />
			<input type="button" style="width:50px;text-decoration:underline;" onClick="surroundText(\'[u]\', \'[/u]\', document.forms.submitform.content); return false;" value="u" />
			<input type="button" style="width:50px;" onClick="surroundText(\'[url]\', \'[/url]\', document.forms.submitform.content); return false;" value="url" />
			<input type="button" style="width:50px;" onClick="surroundText(\'[img]\', \'[/img]\', document.forms.submitform.content); return false;" value="img" />
			<input type="button" style="width:50px;" onClick="surroundText(\'[code]\', \'[/code]\', document.forms.submitform.content); return false;" value="code" /></td>
			</tr>';
		}
		else
		{
			print '<script src="http://js.nicedit.com/nicEdit.js" type="text/javascript"></script><script type="text/javascript">bkLib.onDomLoaded(nicEditors.allTextAreas);</script>' if($config->{useWYSIWYG} == 1);
		}
		print '<tr><td>Content<br /><a href="?do=showSmilies" target="_blank">Show Smilies</a></td><td><textarea name=content cols='.$config->{textAreaCols}.'"';
		print ' style="height: 400px; width: 400px;" ' if( ($config->{useWYSIWYG} == 1) && ($config->{useHtmlOnEntries} == 1) );
		print ' rows="'.$config->{textAreaRows}.'" id="content">';
		if($config->{useHtmlOnEntries} == 0)
		{
			print bbdecode($content);
		}
		else
		{
			print $content;
		}
		print '</textarea></td></tr><tr><td>Category<br />(Available: ';
		my @categories = getCategories();
		my $i = 1;
		foreach(@categories)
		{
			if($i < scalar(@categories))	# Here we display a comma between categories so is easier to undesrtand
			{
				print $_.', ';
			}
			else
			{
				print $_;
			}
			$i++;
		}
		print ')</td>
		<td><input name="category" type="text" id="category" value="'.$category.'"></td>
		</tr>
		<tr>
		<td>Admin Password</td>
		<td><input name="pass" type="password" id="pass">
		<input name="process" type="hidden" id="process" value="editEntry">
		<input name="fileName" type="hidden" id="fileName" value="'.$fileName.'"></td>
		</tr>
		<tr>
		<td>&nbsp;</td>
		<td><input type="submit" name="Submit" value="Edit Post"></td>
		</tr>
		</table>
		</form>';
	}
	else
	{
		print 'Wrong Pass.';
	}
}
elsif(r('process') eq 'editEntry')
{
	# Edit process

	my $pass = r('pass');
	if($pass eq $config->{adminPass})
	{
		my $title = r('title');
		my $content = '';
		if($config->{useHtmlOnEntries} == 0)
		{
			$content = bbcode(r('content'));
		}
		else
		{
			$content = basic_r('content');
		}
		my $category = r('category');
		my $fileName = r('fileName');

		open(FILE, "+>$config->{postsDatabaseFolder}/$fileName.$config->{dbFilesExtension}");

		if($title eq '' or $content eq '' or $category eq '')
		{
			die("All fields are neccesary!");
		}

		my $date = getdate($config->{gmt});
		print FILE $title.'"'.$content.'"'.$date.'"'.$category.'"'.$fileName;	# 0: Title, 1: Content, 2: Date, 3: Category, 4: FileName
		print 'Your post '.$title.' has been edited. <a href="?viewDetailed='.$fileName.'">Go Back</a>';
		close FILE;
	}
	else
	{
		print 'Wrong password!';
	}
}
elsif(r('delete') ne '')
{
	# Delete Post Page

	my $fileName = r('delete');
	print '<h1>Deleting Post...</h1>
	<form accept-charset="UTF-8"   name="form1" method="post">
	<table>
	<td>Admin Password</td>
	<td><input name="pass" type="password" id="pass">
	<input name="process" type="hidden" id="process" value="deleteEntry">
	<input name="fileName" type="hidden" id="fileName" value="'.$fileName.'"></td>
	</tr>
	<tr>
	<td>&nbsp;</td>
	<td><input type="submit" name="Submit" value="Delete Post"></td>
	</tr>
	</table>
	</form>';
}
elsif(r('process') eq 'deleteEntry')
{
	# Delete Post Process

	my $pass = r('pass');

	if($pass eq $config->{adminPass})
	{
		my $fileName = r('fileName');
		my @pages = getPages();
		my $isPage = 0;
		foreach(@pages)
		{
			if($_ == $fileName)
			{
				$isPage = 1;
				last;
			}
		}

		my $newPages;
		if($isPage == 1)
		{
			foreach(@pages)
			{
				if($_ != $fileName)
				{
					$newPages.=$_.'-';
				}
			}

			open(FILE, "+>$config->{postsDatabaseFolder}/pages.$config->{dbFilesExtension}.page");
			print FILE $newPages;
			close FILE;
		}

		unlink("$config->{postsDatabaseFolder}/$fileName.$config->{dbFilesExtension}");
		print 'Entry deleted. <a href="?page=1">Go to Index</a>';
	}
	else
	{
		print 'Wrong password!';
	}
}
elsif(r('do') eq 'search')
{
	# Search Function

	my $keyword = r('keyword');
	my $do = 1;

	if(length($keyword) < $config->{searchMinLength})
	{
		print 'The keyword must be at least '.$config->{searchMinLength}.' characters long!';
		$do = 0;
	}

	my $by = r('by');							# This can be 0 (by title) or 1 (by id) based on the splitted array
	if(($by != 0) && ($by != 1)){ $by = 0; }	# Just prevention from CURL or something...
	my $sBy = $by == 0 ? 'Title' : 'Content';	# This is a shorter way of "my $sBy = ''; if($by == 0) { $sBy = 'Title'; } else { $sBy = 'Content'; }"

	if($do == 1)
	{
		print 'Searching for '.$keyword.' by '.$sBy.'...<br /><br />';
		my @entries = getFiles($config->{postsDatabaseFolder});
		my $matches = 0;
		foreach(@entries)
		{
			my @currEntry = split(/"/, $_);
			if(($currEntry[$by] =~ m/$keyword/i))
			{
				print '<a href="?viewDetailed='.$currEntry[4].'">'.$currEntry[0].'</a><br />';
				$matches++;
			}
		}
		print '<br /><center>'.$matches.' Matches Found.</center>';
	}
}
elsif(r('viewDetailed') ne '')
{
	# Display Individual Entry

	my $fileName = r('viewDetailed');
	my $do = 1;

	unless(-e "$config->{postsDatabaseFolder}/$fileName.$config->{dbFilesExtension}")
	{
		print 'Sorry, that entry does not exists or it has been deleted.';
		$do = 0;
	}

	# First Display Entry
	if($do == 1)		# Checks if the file exists before doing all this
	{
		my $tempContent;
		open(FILE, "<$config->{postsDatabaseFolder}/$fileName.$config->{dbFilesExtension}");
		while(<FILE>)
		{
			$tempContent.=$_;
		}
		close FILE;
		my @entry = split(/"/, $tempContent);
		my $fileName = $entry[4];
		my $title = $entry[0];
		my $content = $entry[1];
		my $category = $entry[3];
		print '<i style="float : right; font-size : .8em;">'.$entry[2] . '</i>
		<h1>'.$entry[0].'</h1>'.$entry[1].'<br /><br />
		<div class="postinfo" style="text-align : right;">
			<i>Category: <a href="?viewCat='.$entry[3].'">'.$entry[3].'</a>
			<br />
			<div>
				<a href="?edit='.$entry[4].'">Edit</a> - <a href="?delete='.$entry[4].'">Delete</a></i>
			</div>
		</div>
		<br /><br />
		';

		# Now Display Comments
		unless(-d $config->{commentsDatabaseFolder})		# Does the comments folder exists? We will save comments there...
		{
			mkdir($config->{commentsDatabaseFolder}, 0755);
		}

		my $content = '';
		open(FILE, "<$config->{commentsDatabaseFolder}/$fileName.$config->{dbFilesExtension}");
		while(<FILE>)
		{
			$content.=$_;
		}
		close FILE;

		print '<h1>Comments:</h1>';
		if($content eq '')
		{
			print 'No comments posted yet.';
		}
		else
		{

			my @comments = split(/'/, $content);

			if($config->{commentsDescending} == 1)
			{
				@comments = reverse(@comments);			# We want the newest first? (Edit at the top on the configuration if you do want newest first)
			}

			my $i = 0;
			foreach(@comments)
			{
				my @comment = split(/"/, $_);
				my $title = $comment[0];
				my $author = $comment[1];
				my $content = $comment[2];
				my $date = $comment[3];
				print '<div class="comment">
				<span style="font-size : .8em; float: right;">By <b>'.$author.'</b> - <i>'.$date.'</i></span>
				<span><b>'.$title.'</b></span>
				<br />
				<br />';
				if($config->{bbCodeOnCommentaries} == 0)
				{
					print txt2html($content);
				}
				else
				{
					print bbcode($content);
				}
				$i++;	# This is used for Deleting comments, to i know what comment number is it :]

				print '<br /><i><a style="float : right;" href="?deleteComment='.$fileName.'.'.$i.'">Delete</a></i>
				</div>'
			}
		}
		# Add comment form
		if($config->{allowComments} == 1)
		{
			print '<br /><br /><div class="addcomment"><h1 style="text-align: right;">Add Comment</h1>
			<form accept-charset="UTF-8"   name="submitform" method="post" style="margin-left: 2em;">
			<table style="width : 100%;">
			<tr>
			<td>Title</td>
			<td><input name="title" type="text" id="title"></td>
			</tr>
			<tr>
			<td>Author</td>
			<td><input name="author" type="text" id="author"></td>
			</tr>';

			print '<tr>
			<td>&nbsp;</td>
			<td><input type="button" style="width:50px;font-weight:bold;" onClick="surroundText(\'[b]\', \'[/b]\', document.forms.submitform.content); return false;" value="b" />
			<input type="button" style="width:50px;font-style:italic;" onClick="surroundText(\'[i]\', \'[/i]\', document.forms.submitform.content); return false;" value="i" />
			<input type="button" style="width:50px;text-decoration:underline;" onClick="surroundText(\'[u]\', \'[/u]\', document.forms.submitform.content); return false;" value="u" />
			<input type="button" style="width:50px;" onClick="surroundText(\'[url]\', \'[/url]\', document.forms.submitform.content); return false;" value="url" />
			<input type="button" style="width:50px;" onClick="surroundText(\'[img]\', \'[/img]\', document.forms.submitform.content); return false;" value="img" />
			<input type="button" style="width:50px;" onClick="surroundText(\'[code]\', \'[/code]\', document.forms.submitform.content); return false;" value="code" /></td>
			</tr>' if $config->{allowBBcodeButtonsOnComments} == 1 && $config->{bbCodeOnCommentaries} == 1;

			print '<tr>
			<td>Content<br /><a href="?do=showSmilies" target="_blank">Show Smilies</a></td>
			<td><textarea name="content" id="content" rows="'.$config->{textAreaRows}.'" style="width : 80%;"></textarea></td>
			</tr>
			<tr>';

			if($config->{commentsSecurityCode} == 1)
			{
				my $code = '';
				if($config->{onlyNumbersOnCAPTCHA} == 1)
				{
					$code = substr(rand(999999),1,$config->{CAPTCHALength});
				}
				else
				{
					$code = uc(substr(crypt(rand(999999), $config->{randomString}),1,$config->{CAPTCHALength}));
				}
				$code =~ s/\.//;
				$code =~ s/\///;
				print '<td></td>
				<td><font face="Verdana, Arial, Helvetica, sans-serif" size="2">'.$code.'</font><input name="originalCode" value="'.$code.'" type="hidden" id="originalCode"></td>
				</tr>
				<tr>
				<td>Type  Code Above</td>
				<td><input name="code" type="text" id="code"> &nbsp;  &nbsp;  &nbsp;  (Used to verify human)</td>
				</tr>';
			}

			print '<tr>
			<td>'.$config->{commentsSecurityQuestion}.'</td>
			<td><input name="question" type="text" id="question">
				 &nbsp;  &nbsp;  &nbsp; (Get the answer from the administrator)</td>
</td>
			</tr>
			<tr>' if $config->{securityQuestionOnComments} == 1;

			print '<tr>
			<td>Author&apos;s Password</td>
			<td><input name="pass" type="password" id="pass"> &nbsp; &nbsp; &nbsp; (Create or Reuse a created one)</td>
			</tr>
			<tr>
			<td>&nbsp;</td>
			<td><input style="float: right;" type="submit" name="Submit" value="Add Comment"><input name="sendComment" value="'.$fileName.'" type="hidden" id="sendComment"></td>
			</tr>
			</table>
			</form>
			</div>';
		}
	}
}
elsif(r('sendComment') ne '')
{
	# Send Comment Process

	my $fileName = r('sendComment');
	my $title = r('title');
	my $author = r('author');
	my $content = r('content');
	my $pass = r('pass');
	my $date = getdate($config->{gmt});
	my $do = 1;
	my $triedAsAdmin = 0;

	if($title eq '' || $author eq '' || $content eq '' || $pass eq '')
	{
		print 'All fields are neccessary. Go back and fill them all.';
		$do = 0;
	}

	if($config->{commentsSecurityCode} == 1)
	{
		my $code = r('code');
		my $originalCode = r('originalCode');

		unless($code eq $originalCode)
		{
			print 'Security Code does not match. Please, try again';
			$do = 0;
		}
	}

	if($config->{securityQuestionOnComments} == 1)
	{
		my $question = r('question');
		unless(lc($question) eq lc($config->{commentsSecurityAnswer}))
		{
			print 'Incorrect security answer. Please, try again.';
			$do = 0;
		}
	}

	my $hasPosted = 0;					# This is to see if the user has posted already, so we add him/her to the database :]

	foreach($config->{commentsForbiddenAuthors})
	{
		if($_ eq $author)
		{
			unless($pass eq $config->{adminPass})		# Prevent users from using nicks like "admin"
			{
				$do = 0;
				print 'Wrong password for using '.$_.' as nickname';
				last;
			}
			else
			{
				$hasPosted = 1;
			}
			$triedAsAdmin = 1;
		}
	}

	# Start of author checking, for identity security
	open(FILE, "<$config->{commentsDatabaseFolder}/users.$config->{dbFilesExtension}.dat");
	my $data = '';
	while(<FILE>)
	{
		$data.=$_;
	}
	close(FILE);

	if($triedAsAdmin == 0)
	{
		my @users = split(/"/, $data);
		foreach(@users)
		{
			my @data = split(/'/, $_);
			if($author eq $data[0])
			{
				$hasPosted = 1;
				if(crypt($pass, $config->{randomString}) ne $data[1])
				{
					$do = 0;
					print 'The username '.$author.' is already taken and that password is incorrect. Please choose other author or try again.';
				}
				last;
			}
		}
	}

	if($hasPosted == 0)
	{
		open(FILE, ">>$config->{commentsDatabaseFolder}/users.$config->{dbFilesExtension}.dat");
		print FILE $author."'".crypt($pass, $config->{randomString}).'"';
		close FILE;
		print 'You are a new user posting here... You will be added to a database so nobody can steal your identity. Remember your password!<br>';
	}
	# End of author checking, start adding comment

	if($do == 1)
	{
		if($title eq '' or $author eq '' or $content eq '')
		{
			print 'All fields are neccessary.';
		}
		else
		{
			if(length($content) > $config->{commentsMaxLenght})
			{
				print 'The content is too long! Max characters is '.$config->{commentsMaxLenght}.' you typed '.length($content);
			}
			else
			{
				my $content = $title.'"'.$author.'"'.$content.'"'.$date.'"'.$fileName."'";

				# Add comment
				open(FILE, ">>$config->{commentsDatabaseFolder}/$fileName.$config->{dbFilesExtension}");
				print FILE $content;
				close FILE;

				# Add coment number to a file with latest comments
				open(FILE, ">>$config->{commentsDatabaseFolder}/latest.$config->{dbFilesExtension}");
				print FILE $content;
				close FILE;

				print 'Comment added. Thanks '.$author.'!<br /><center><a href="?viewDetailed='.$fileName.'">Go Back</a></center>';

				# If Comment Send Mail is active
				if($config->{sendMailWithNewComment} == 1)
				{
					my $content = "Hello, i am sending this mail beacuse $author commented on your blog: http://".$ENV{'HTTP_HOST'}.$ENV{'REQUEST_URI'}."\nTitle: $title\nComment: $content\nDate: $date\n\nRemember you can disallow this option changing the ".'$config->{sendMailWithNewComment} Variable to 0';
					open (MAIL,"|/usr/lib/sendmail -t");
					print MAIL "To: $config->{sendMailWithNewCommentMail}\n";
					print MAIL "From: pBlog \n";
					print MAIL "Subject: New Comment on your pBlog\n\n";
					print MAIL $content;
					close(MAIL);
				}
			}
		}
	}
}
elsif(r('deleteComment') ne '')
{
	# Delete Comment

	my $data = r('deleteComment');

	print '<h1>Deleting Comment...</h1>
	<form accept-charset="UTF-8"   name="form1" method="post">
	<table>
	<td>Admin Password</td>
	<td><input name="pass" type="password" id="pass">
	<input name="process" type="hidden" id="process" value="deleteComment">
	<input name="data" type="hidden" id="data" value="'.$data.'"></td>
	</tr>
	<tr>
	<td>&nbsp;</td>
	<td><input type="submit" name="Submit" value="Delete Comment"></td>
	</tr>
	</table>
	</form>';
}
elsif(r('process') eq 'deleteComment')
{
	# Delete Comment Process

	my $pass = r('pass');
	if($pass eq $config->{adminPass})
	{
		my $data = r('data');
		my @info = split(/\./, $data);
		my $fileName = $info[0];
		my $part = $info[1];
		my $commentToDelete;

		my $content = '';
		open(FILE, "<$config->{commentsDatabaseFolder}/$fileName.$config->{dbFilesExtension}");
		while(<FILE>)
		{
			$content.=$_;
		}
		close FILE;

		my @comments = split(/'/, $content);

		if($config->{commentsDescending} == 1)
		{
			@comments = reverse(@comments);
		}

		my $newContent = '';

		my $i = 0;
		my @newComments;
		foreach(@comments)
		{
			if($i != $part)
			{
				push(@newComments, $_);
			}
			else
			{
				$commentToDelete = $_;
			}
			$i++;
		}

		if($i == 1)		# There was only 1 comment
		{
			unlink("$config->{commentsDatabaseFolder}/$fileName.$config->{dbFilesExtension}");
		}
		else
		{
			reverse(@newComments);

			foreach(@newComments)
			{
				$newContent.=$_."'";
			}

			open(FILE, "+>$config->{commentsDatabaseFolder}/$fileName.$config->{dbFilesExtension}");	# Open for writing, and delete everything else
			print FILE $newContent;
			close FILE;
		}

		# Now delete comment from the latest comments file where all comments are saved
		open(FILE, "<$config->{commentsDatabaseFolder}/latest.$config->{dbFilesExtension}");
		$newContent = '';
		while(<FILE>)
		{
			$newContent.=$_;
		}
		close FILE;

		my @comments = split(/'/, $newContent);
		my $finalCommentsToAdd;
		foreach(@comments)
		{
			unless($_ eq $commentToDelete)
			{
				$finalCommentsToAdd.=$_."'";
			}
		}

		open(FILE, "+>$config->{commentsDatabaseFolder}/latest.$config->{dbFilesExtension}");	# Open for writing, and delete everything else
		print FILE $finalCommentsToAdd;
		close FILE;

		# Finally print this
		print 'Comment deleted. <a href="?viewDetailed='.$fileName.'">Go Back</a>';
	}
	else
	{
		print 'Wrong password!';
	}
}
elsif(r('do') eq 'archive')
{
	# Show blog archive

	print '<h1>Archive</h1>';
	my @entries = getFiles($config->{postsDatabaseFolder});
	print 'No entries created yet.' if scalar(@entries) == 0;
	# Split the data in the post so i have them in this format "13 Dic 2008, 24:11|0001|Entry title" date|fileName|entryTitle
	my @dates = map { split(/"/, $_); @_[2].'|'.@_[4].'|'.@_[0]; } @entries;
	my @years;
	foreach(@dates)
	{
		my @date = split(/\|/, $_);
		my @y = split(/\s/, $date[0]);
		$y[2] =~ s/,//;
		if($y[2] =~ /^\d+$/)
		{
			push(@years, $y[2]);
		}
	}
	@years = reverse(sort(array_unique(@years)));
	for my $actualYear(@years)
	{
		print '<b>Year '.$actualYear.'</b><br />';
		# Now i make my hash with the empty months, why define them? because this is the order they will be executed
		my %months = ('Jan'=>'', 'Feb'=>'', 'Mar'=>'', 'Apr'=>'', 'May'=>'','Jun'=>'','Jul'=>'','Aug'=>'','Sep'=>'','Oct'=>'','Nov'=>'','Dic'=>'');
		# Array with all entries from that year
		my @entries = grep { /$actualYear/; } @dates;
		# Now assign the post number to the hash
		foreach(@entries)
		{
			my @d = split(/\s/, $_);
			my @e = split(/\|/, $_);
			$months{$d[1]} .= $e[0].'|'.$e[1].'|'.$e[2].'&-;';
		}
		# Now i have my months hash with a string to be splitted into all posts from that month
		while(my($k, $v) = each(%months))
		{
			unless($k =~ /^\d/)
			{
				print '<br /><b>'.$k.':</b><br /><table>' unless $v eq '';
				# Here are all entries from this month, sort them in ascending order, oldest first
				my @entries = sort{$a <=> $b}reverse((split(/&-;/, $months{$k})));	# Why reverse if then im sorting, well so days are in ascending order
				foreach(@entries)
				{
					my @data = split(/\|/, $_);
					my @d = map {split(/\s/, $_); @_[0]} split(/,/, $data[0]);
					print '<tr>
					<td>Day '.$d[0].':</td>
					<td><a href="?viewDetailed='.$data[1].'">'.$data[2].'</a></td>
					</tr>';
				}
				print '</table>' unless $v eq '';
			}
		}
	}
}
elsif(r('do') eq 'listComments')
{
	print '<h1>Listing All Comments</h1>';
	my @comments = getComments();
	# This is pagination... Again :]
	my $page = r('page');												# The current page
	if($page eq ''){ $page = 1; }										# Makes page 1 the default page (Could be... $page = 1 if $page eq '')
	my $totalPages = ceil((scalar(@comments))/$config->{commentsPerPage});	# How many pages will be?
	# What part of the array should i show in the page?
	my $arrayEnd = ($config->{commentsPerPage}*$page);						# The array will start from this number
	my $arrayStart = $arrayEnd-($config->{commentsPerPage}-1);				# And loop till this number
	# As arrays start from 0, i will lower 1 to these values
	$arrayEnd--;
	$arrayStart--;
	my $i = $arrayStart;												# Start Looping...
	if(scalar(@comments) > 0)
	{
		print '<table width="100%">
		<thead>
			<tr><th>Date</th><th><i>Author</i></th><th><i>Title</i></th></tr>
		</thead>
		<tbody>';
	}
	else
	{
		print 'No comments added yet.';
	}
	while($i<=$arrayEnd)
	{
		unless($comments[$i] eq '')
		{
			my @finalEntries = split(/"/, $comments[$i]);
			my @pages = getPages();
			my $do = 1;
			foreach(@pages)
			{
				if($_ == $finalEntries[4])
				{
					$do = 0;
					last;
				}
			}

			if($do == 1)
			{
				print '<tr><td> '.$finalEntries[3].'</td><td style="text-transform: capitalize;"><b>'.$finalEntries[1].'</b></td><td><a href="?viewDetailed='.$finalEntries[4].'">'.$finalEntries[0].'</a></td></tr>';
			}
		}
		$i++;
	}
	# Now i will display the pages
	print '</tbody></table><center> Pages: ' if scalar(@comments) > 0;
	my $startPage = $page == 1 ? 1 : ($page-1);
	my $displayed = 0;
	for(my $i = $startPage; $i <= (($page-1)+$config->{maxPagesDisplayed}); $i++)
	{
		if($i <= $totalPages)
		{
			if($page != $i)
			{
				if($i == (($page-1)+$config->{maxPagesDisplayed}) && (($page-1)+$config->{maxPagesDisplayed}) < $totalPages)
				{
					print '<a href="?do=listComments&page='.$i.'">['.$i.']</a> ...';
				}
				elsif($startPage > 1 && $displayed == 0)
				{
					print '... <a href="?do=listComments&page='.$i.'">['.$i.']</a> ';
					$displayed = 1;
				}
				else
				{
					print '<a href="?do=listComments&page='.$i.'">['.$i.']</a> ';
				}
			}
			else
			{
				print '['.$i.'] ';
			}
		}
	}
	print '</center>';
}
elsif(r('do') eq 'showSmilies')
{
	if(-d "$config->{smiliesFolder}")
	{
		if(opendir(DH, $config->{smiliesFolder}))
		{
			my @smilies;
			print '<h1>Smilies</h1><table width="100%"><tr><td>Smilie</td><td>Code</td></tr>';
			@smilies = grep {/gif/ || /jpg/ || /png/;} readdir(DH);
			foreach(@smilies)
			{
				my @n = split(/\./, $_);
				print '<tr><td><img src="'.$config->{smiliesFolderName}.'/'.$_.'" /></td><td>:'.$n[0].':</td></tr>';
			}
			print '</table>';
		}
		else
		{
			print 'Error opening '.$config->{smiliesFolder}.' folder.';
		}
	}
	else
	{
		print 'The admin owner did not allow smilies for this blog.';
	}
}
else
{
	# Blog Main Page
	my @entries = getFiles($config->{postsDatabaseFolder});
	if(scalar(@entries) != 0)
	{
		# Pagination - This is the so called Pagination
		my $page = r('page');												# The current page
		if($page eq ''){ $page = 1; }										# Makes page 1 the default page
		my $totalPages = ceil((scalar(@entries))/$config->{entriesPerPage});	# How many pages will be?
		# What part of the array should i show in the page?
		my $arrayEnd = ($config->{entriesPerPage}*$page);						# The array will start from this number
		my $arrayStart = $arrayEnd-($config->{entriesPerPage}-1);				# And loop till this number
		# As arrays start from 0, i will lower 1 to these values
		$arrayEnd--;
		$arrayStart--;

		my $i = $arrayStart;												# Start Looping...
		while($i<=$arrayEnd)
		{
			unless($entries[$i] eq '')
			{
				my @finalEntries = split(/"/, $entries[$i]);
				my @pages = getPages();
				my $do = 1;
				foreach(@pages)
				{
					if($_ == $finalEntries[4])
					{
						$do = 0;
						last;
					}
				}

				if($do == 1)
				{
					# This is for displaying how many comments are posted on that entry
					my $commentsLink;
					my $content;
					open(FILE, "<$config->{commentsDatabaseFolder}/$finalEntries[4].$config->{dbFilesExtension}");
					while(<FILE>){$content.=$_;}
					close FILE;

					my @comments = split(/'/, $content);
					if(scalar(@comments) == 0)
					{
						$commentsLink = 'No comments';
					}
					elsif(scalar(@comments) == 1)
					{
						$commentsLink = '1 Comment';
					}
					else
					{
						$commentsLink = scalar(@comments).' Comments';
					}

					my $w2 = "";
					my $e = "";

					if ($#entries < 1)
					{
						$w2 = $finalEntries[1];
					}
					else
					{
						my @w = split(/ /, $finalEntries[1]);
						my $i = 0;
						while ($i <= 10)
						{
							$w2 = $w2 . ' ' . $w[$i];
							$i++;
						}

						if ($#w > 10)
						{
							$e = "...";
						}
					}

					print '<div class="post">
						<i style="float : right; font-size : .8em;">'.$finalEntries[2] . '</i>
						<a href="?viewDetailed='.$finalEntries[4].'">
						<h1>'.$finalEntries[0].'</h1>
						</a>
						<div class="entry">'
							. $w2 . ' ' . $e . '
						</div>';
							if ($#entries < 1 && $finalEntries[2] != '' )
							{
								print '<div class="postinfo">
									<i>Posted on '.$finalEntries[2].' in Category: <a href="?viewCat='.$finalEntries[3].'">'.$finalEntries[3].'</a>
										<br /><div class="right"><a href="?edit='.$finalEntries[4].'">Edit</a> - <a href="?delete='.$finalEntries[4].'">Delete</a></div></i>
								</div>';
							}
					print '
						<br />
						<i style="float: right">Category: <a href="?viewCat='.$finalEntries[3].'">'.$finalEntries[3].'</a></i>
						<br />
					</div>';

				}
			}
			$i++;
		}
		# Now i will display the pages
		print '<center> Pages: ';
		my $startPage = $page == 1 ? 1 : ($page-1);
		my $displayed = 0;
		for(my $i = $startPage; $i <= (($page-1)+$config->{maxPagesDisplayed}); $i++)
		{
			if($i <= $totalPages)
			{
				if($page != $i)
				{
					if($i == (($page-1)+$config->{maxPagesDisplayed}) && (($page-1)+$config->{maxPagesDisplayed}) < $totalPages)
					{
						print '<a href="?page='.$i.'">['.$i.']</a> ...';
					}
					elsif($startPage > 1 && $displayed == 0)
					{
						print '... <a href="?page='.$i.'">['.$i.']</a> ';
						$displayed = 1;
					}
					else
					{
						print '<a href="?page='.$i.'">['.$i.']</a> ';
					}
				}
				else
				{
					print '['.$i.'] ';
				}
			}
		}
		print '</center>';
	}
	else
	{
		print 'No entries created. Why dont you <a href="?do=newEntry">make one</a>?';
	}
}
my $year = 1900 + (localtime)[5];
print '</div><div id="footer">Copyright '.$config->{blogTitle}.' '.$year.' - All Rights Reserved - Powered by <a href="https://github.com/escapecode/pBlog">pBlog</a>'; print '<br>All posts are using GMT '.$config->{gmt} if $config->{showGmtOnFooter} == 1; print '</div></div></body></html>';
}