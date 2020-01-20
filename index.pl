#!/usr/bin/perl -U

#####################################################
# 	pBlog (Perl Powered Blog)						#
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

#sub bbcode
#{
	#$_ = $_[0];
	#s/\n/<br \/>/gi;
	#s/\[b\](.+?)\[\/b\]/<b>$1<\/b>/gi;
	#s/\[i\](.+?)\[\/i\]/<i>$1<\/i>/gi;
	#s/\[u\](.+?)\[\/u\]/<u>$1<\/u>/gi;
	#s/\[\*\](.+?)\[\/\*\]/<li>$1<\/li>/gi;
	#s/\[center\](.+?)\[\/center\]/<center>$1<\/center>/gi;
	#s/\[url\](.+?)\[\/url\]/<a href=$1 target=_blank>$1<\/a>/gi;
	#s/\[url=(.+?)\](.+?)\[\/url\]/<a href=$1 target=_blank>$2<\/a>/gi;
	#s/\[img\](.+?)\[\/img\]/<img src=$1 \/>/gi;
	#s/\[code\](.+?)\[\/code\]/<div class=code><pre>$1<\/pre><\/div>/gi;
	#s/\[quote\](.+?)\[\/quote\]/<div class=quote>$1<\/div>/gi;
	#if(-d "$config->{smiliesFolder}")
	#{
		#my @smilies;
		#my $s;
		#if(opendir(DH, $config->{smiliesFolder}))
		#{
			#@smilies = grep {/gif/ || /jpg/ || /png/;} readdir(DH);
		#}
		#foreach $s(@smilies)
		#{
			#my @i = split(/\./, $s);
			#s/\:$i[0]\:/<img src=$config->{smiliesFolderName}\/$i[0].$i[1] \/>/gi;
		#}
	#}
	#return $_;
#}

#sub bbdecode
#{
	#$_ = $_[0];
	#s/\n//;
	#s/<br \/>//gi;
	#s/\<b\>(.+?)\<\/b\>/\[b\]$1\[\/b\]/gi;
	#s/\<i\>(.+?)\<\/i\>/\[i\]$1\[\/i\]/gi;
	#s/\<u\>(.+?)\<\/u\>/\[u\]$1\[\/u\]/gi;
	#s/\<li\>(.+?)\<\/li\>/\[\*\]$1\[\/\*\]/gi;
	#s/\<center\>(.+?)\<\/center\>/\[center\]$1\[\/center\]/gi;
	#s/\<a href=(.+?)\ target=_blank\>(.+?)\<\/a\>/\[url=$1\]$2\[\/url\]/gi;
	#s/\<img src=(.+?) \/>/\[img\]$1\[\/img\]/gi;
	#s/\<div class=code\>\<pre\>(.+?)\<\/pre\>\<\/div\>/\[code\]$1\[\/code\]/gi;
	#s/\<div class=quote\>(.+?)\<\/div\>/\[quote\]$1\[\/quote\]/gi;
	#return $_;
#}

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

sub printTextEditor($)
{
	my $content_text = shift;
	#my $content_text = $_[0];

	print '
		<input type="hidden" name="myDoc">
		<div id="toolBar1">
		<select onchange="formatDoc(\'formatblock\',this[this.selectedIndex].value);this.selectedIndex=0;">
			<option selected>- formatting -</option>
			<option value="h1">Title 1 &lt;h1&gt;</option>
			<option value="h2">Title 2 &lt;h2&gt;</option>
			<option value="h3">Title 3 &lt;h3&gt;</option>
			<option value="h4">Title 4 &lt;h4&gt;</option>
			<option value="h5">Title 5 &lt;h5&gt;</option>
			<option value="h6">Subtitle &lt;h6&gt;</option>
			<option value="p">Paragraph &lt;p&gt;</option>
			<option value="pre">Preformatted &lt;pre&gt;</option>
		</select>
		<select onchange="formatDoc(\'fontname\',this[this.selectedIndex].value);this.selectedIndex=0;">
			<option class="heading" selected>- font -</option>
			<option>Arial</option>
			<option>Arial Black</option>
			<option>Courier New</option>
			<option>Times New Roman</option>
		</select>
		<select onchange="formatDoc(\'fontsize\',this[this.selectedIndex].value);this.selectedIndex=0;">
			<option class="heading" selected>- size -</option>
			<option value="1">Very small</option>
			<option value="2">A bit small</option>
			<option value="3">Normal</option>
			<option value="4">Medium-large</option>
			<option value="5">Big</option>
			<option value="6">Very big</option>
			<option value="7">Maximum</option>
		</select>
		<select onchange="formatDoc(\'forecolor\',this[this.selectedIndex].value);this.selectedIndex=0;">
			<option class="heading" selected>- color -</option>
			<option value="red">Red</option>
			<option value="blue">Blue</option>
			<option value="green">Green</option>
			<option value="black">Black</option>
		</select>
		<select onchange="formatDoc(\'backcolor\',this[this.selectedIndex].value);this.selectedIndex=0;">
			<option class="heading" selected>- background -</option>
			<option value="red">Red</option>
			<option value="green">Green</option>
			<option value="black">Black</option>
		</select>
	</div>
	<div id="toolBar2">
				<img class="intLink" title="Save" onclick="download(document.getElementById(\'textBox\').innerHTML, \'output.html\', \'text/html\');" src="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjxzdmcKICAgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIgogICB4bWxuczpjYz0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbnMjIgogICB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiCiAgIHhtbG5zOnN2Zz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciCiAgIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKICAgaWQ9InN2Zzg2NyIKICAgd2lkdGg9IjIyIgogICBoZWlnaHQ9IjIyIgogICB2ZXJzaW9uPSIxLjEiPgogIDxtZXRhZGF0YQogICAgIGlkPSJtZXRhZGF0YTg3MyI+CiAgICA8cmRmOlJERj4KICAgICAgPGNjOldvcmsKICAgICAgICAgcmRmOmFib3V0PSIiPgogICAgICAgIDxkYzpmb3JtYXQ+aW1hZ2Uvc3ZnK3htbDwvZGM6Zm9ybWF0PgogICAgICAgIDxkYzp0eXBlCiAgICAgICAgICAgcmRmOnJlc291cmNlPSJodHRwOi8vcHVybC5vcmcvZGMvZGNtaXR5cGUvU3RpbGxJbWFnZSIgLz4KICAgICAgICA8ZGM6dGl0bGU+PC9kYzp0aXRsZT4KICAgICAgPC9jYzpXb3JrPgogICAgPC9yZGY6UkRGPgogIDwvbWV0YWRhdGE+CiAgPGRlZnMKICAgICBpZD0iZGVmczg3MSIgLz4KICA8cGF0aAogICAgIGlkPSJwYXRoODUzIgogICAgIGQ9Ik0gNS4zNDg3NDg4LDE2LjE2NTQ2NiBWIDUuOTY0MTA3NiBjIDAsLTAuMzc3ODI4MSAwLjEyNTk0MjcsLTAuNTAzNzcwOCAwLjUwMzc3MDgsLTAuNTAzNzcwOCBIIDE2LjY4MzU5MSBjIDAuMzc3ODI5LDAgMC41MDM3NzEsMC4yNTE4ODU0IDAuNTAzNzcxLDAuNjI5NzEzNSBWIDE2Ljc5NTE4IGMgMCwwLjI1MTg4NSAwLDAuNTAzNzcgLTAuNTAzNzcxLDAuNTAzNzcgSCA2LjQ4MjIzMzEgWiIKICAgICBzdHlsZT0iZmlsbDojODg4ODg4O3N0cm9rZTojMjIyMjIyO3N0cm9rZS13aWR0aDowLjE4ODkxNDA1cHgiIC8+CiAgPHBhdGgKICAgICBpZD0icGF0aDg1NSIKICAgICBkPSJNIDUuNzI2NTc2OSw1LjgzODE2NDkgViAxNi4wMzk1MjMgbCAwLjg4MTU5ODksMC44ODE1OTkgSCAxNi44MDk1MzQgViA1LjgzODE2NDkgWiIKICAgICBzdHlsZT0iZmlsbDojNTU1NTU1O3N0cm9rZS13aWR0aDowLjEyNTk0MjY5IiAvPgogIDxwYXRoCiAgICAgaWQ9InBhdGg4NTciCiAgICAgZD0ibSA4LjQ5NzMxNjIsMTIuODkwOTU2IGMgLTAuNTAzNzcwOCwwIC0wLjUwMzc3MDgsMC4yNTE4ODUgLTAuNTAzNzcwOCwwLjUwMzc3MSB2IDMuOTA0MjIzIGggNi41NDkwMjA2IHYgLTMuOTA0MjIzIGMgMCwtMC4yNTE4ODYgLTAuMTI1OTQzLC0wLjUwMzc3MSAtMC41MDM3NzEsLTAuNTAzNzcxIHogbSAxLjI1OTQyNjksMC41MDM3NzEgYyAwLjg4MTU5ODksMCAwLjc1NTY1NTksMC4zNzc4MjggMC43NTU2NTU5LDAuMzc3ODI4IHYgMi4yNjY5NjggYyAwLDAgMC4xMjU5NDMsMC4zNzc4MjggLTAuNzU1NjU1OSwwLjM3NzgyOCAtMC43NTU2NTYyLDAgLTAuNjI5NzEzNSwtMC4zNzc4MjggLTAuNjI5NzEzNSwtMC4zNzc4MjggdiAtMi4yNjY5NjggYyAwLDAgLTAuMTI1OTQyNywtMC4zNzc4MjggMC42Mjk3MTM1LC0wLjM3NzgyOCB6IgogICAgIHN0eWxlPSJmaWxsOiNiYmJiYmI7c3Ryb2tlOiM0NDQ0NDQ7c3Ryb2tlLXdpZHRoOjAuMjUxODg1MzhweCIgLz4KICA8cmVjdAogICAgIGlkPSJyZWN0ODU5IgogICAgIHk9IjUuNTg2Mjc5NCIKICAgICB4PSI3LjExMTk0NjYiCiAgICAgaGVpZ2h0PSIxLjI1OTQyNyIKICAgICB3aWR0aD0iOC4zMTIyMTc3IgogICAgIHN0eWxlPSJmaWxsOiMxYmJiMjg7ZmlsbC1vcGFjaXR5OjAuNztzdHJva2Utd2lkdGg6MC4xMjU5NDI2OSIgLz4KICA8cmVjdAogICAgIGlkPSJyZWN0ODYxIgogICAgIHk9IjYuODQ1NzA2NSIKICAgICB4PSI3LjExMTk0NjYiCiAgICAgaGVpZ2h0PSI1LjI4OTU5MzIiCiAgICAgd2lkdGg9IjguMzEyMjE3NyIKICAgICBzdHlsZT0iZmlsbDojZWVlZWVlO3N0cm9rZS13aWR0aDowLjEyNTk0MjY5IiAvPgogIDxyZWN0CiAgICAgaWQ9InJlY3Q4NjMiCiAgICAgeT0iNi4yMTU5OTM0IgogICAgIHg9IjUuOTc4NDYyMiIKICAgICBoZWlnaHQ9IjAuNzU1NjU2MTgiCiAgICAgd2lkdGg9IjAuNzU1NjU2MTgiCiAgICAgc3R5bGU9ImZpbGw6IzMzMzMzMztzdHJva2Utd2lkdGg6MC4xMjU5NDI2OSIgLz4KICA8cGF0aAogICAgIGlkPSJwYXRoODY1IgogICAgIGQ9Ik0gNy42MTU3MTczLDExLjAwMTgxNiBIIDE0LjkyMDM5NCBNIDcuNjE1NzE3Myw5LjQ5MDUwMjcgSCAxNC45MjAzOTQgTSA3LjYxNTcxNzMsOC4xMDUxMzM3IGggNy4zMDQ2NzY3IgogICAgIHN0eWxlPSJmaWxsOm5vbmU7c3Ryb2tlOiM4ODg4ODg7c3Ryb2tlLXdpZHRoOjAuMjUxODg1MzhweCIgLz4KPC9zdmc+Cg==" />
				<input type="file" id="fileOpen" style="display: none;" onchange="fileLoad.call(this, event)" />
				<img class="intLink" title="Open" onclick="document.getElementById(\'fileOpen\').click();" src="data:image/png;base64,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" />
				<img class="intLink" title="Clean" onclick="if(validateMode()&&confirm(\'Are you sure?\')){oDoc.innerHTML=sDefTxt};" src="data:image/gif;base64,R0lGODlhFgAWAIQbAD04KTRLYzFRjlldZl9vj1dusY14WYODhpWIbbSVFY6O7IOXw5qbms+wUbCztca0ccS4kdDQjdTLtMrL1O3YitHa7OPcsd/f4PfvrvDv8Pv5xv///////////////////yH5BAEKAB8ALAAAAAAWABYAAAV84CeOZGmeaKqubMteyzK547QoBcFWTm/jgsHq4rhMLoxFIehQQSAWR+Z4IAyaJ0kEgtFoLIzLwRE4oCQWrxoTOTAIhMCZ0tVgMBQKZHAYyFEWEV14eQ8IflhnEHmFDQkAiSkQCI2PDC4QBg+OAJc0ewadNCOgo6anqKkoIQA7" />
				<img class="intLink" title="Print" onclick="printDoc();" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAABGdBTUEAALGPC/xhBQAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9oEBxcZFmGboiwAAAAIdEVYdENvbW1lbnQA9syWvwAAAuFJREFUOMvtlUtsjFEUx//n3nn0YdpBh1abRpt4LFqtqkc3jRKkNEIsiIRIBBEhJJpKlIVo4m1RRMKKjQiRMJRUqUdKPT71qpIpiRKPaqdF55tv5vvusZjQTjOlseUkd3Xu/3dPzusC/22wtu2wRn+jG5So/OCDh8ycMJDflehMlkJkVK7KUYN+ufzA/RttH76zaVocDptRxzQtNi3mRWuPc+6cKtlXZ/sddP2uu9uXlmYXZ6Qm8v4Tz8lhF1H+zDQXt7S8oLMXtbF4e8QaFHjj3kbP2MzkktHpiTjp9VH6iHiA+whtAsX5brpwueMGdONdf/2A4M7ukDs1JW662+XkqTkeUoqjKtOjm2h53YFL15pSJ04Zc94wdtibr26fXlC2mzRvBccEbz2kiRFD414tKMlEZbVGT33+qCoHgha81SWYsew0r1uzfNylmtpx80pngQQ91LwVk2JGvGnfvZG6YcYRAT16GFtW5kKKfo1EQLtfh5Q2etT0BIWF+aitq4fDbk+ImYo1OxvGF03waFJQvBCkvDffRyEtxQiFFYgAZTHS0zwAGD7fG5TNnYNTp8/FzvGwJOfmgG7GOx0SAKKgQgDMgKBI0NJGMEImpGDk5+WACEwEd0ywblhGUZ4Hw5OdUekRBLT7DTgdEgxACsIznx8zpmWh7k4rkpJcuHDxCul6MDsmmBXDlWCH2+XozSgBnzsNCEE4euYV4pwCpsWYPW0UHDYBKSWu1NYjENDReqtKjwn2+zvtTc1vMSTB/mvev/WEYSlASsLimcOhOBJxw+N3aP/SjefNL5GePZmpu4kG7OPr1+tOfPyUu3BecWYKcwQcDFmwFKAUo90fhKDInBCAmvqnyMgqUEagQwCoHBDc1rjv9pIlD8IbVkz6qYViIBQGTJPx4k0XpIgEZoRN1Da0cij4VfR0ta3WvBXH/rjdCufv6R2zPgPH/e4pxSBCpeatqPrjNiso203/5s/zA171Mv8+w1LOAAAAAElFTkSuQmCC">
				<img class="intLink" title="Undo" onclick="formatDoc(\'undo\');" src="data:image/gif;base64,R0lGODlhFgAWAOMKADljwliE33mOrpGjuYKl8aezxqPD+7/I19DV3NHa7P///////////////////////yH5BAEKAA8ALAAAAAAWABYAAARR8MlJq7046807TkaYeJJBnES4EeUJvIGapWYAC0CsocQ7SDlWJkAkCA6ToMYWIARGQF3mRQVIEjkkSVLIbSfEwhdRIH4fh/DZMICe3/C4nBQBADs=" />
				<img class="intLink" title="Redo" onclick="formatDoc(\'redo\');" src="data:image/gif;base64,R0lGODlhFgAWAMIHAB1ChDljwl9vj1iE34Kl8aPD+7/I1////yH5BAEKAAcALAAAAAAWABYAAANKeLrc/jDKSesyphi7SiEgsVXZEATDICqBVJjpqWZt9NaEDNbQK1wCQsxlYnxMAImhyDoFAElJasRRvAZVRqqQXUy7Cgx4TC6bswkAOw==" />
				<img class="intLink" title="Cut" onclick="formatDoc(\'cut\');" src="data:image/gif;base64,R0lGODlhFgAWAIQSAB1ChBFNsRJTySJYwjljwkxwl19vj1dusYODhl6MnHmOrpqbmpGjuaezxrCztcDCxL/I18rL1P///////////////////////////////////////////////////////yH5BAEAAB8ALAAAAAAWABYAAAVu4CeOZGmeaKqubDs6TNnEbGNApNG0kbGMi5trwcA9GArXh+FAfBAw5UexUDAQESkRsfhJPwaH4YsEGAAJGisRGAQY7UCC9ZAXBB+74LGCRxIEHwAHdWooDgGJcwpxDisQBQRjIgkDCVlfmZqbmiEAOw==" />
				<img class="intLink" title="Copy" onclick="formatDoc(\'copy\');" src="data:image/gif;base64,R0lGODlhFgAWAIQcAB1ChBFNsTRLYyJYwjljwl9vj1iE31iGzF6MnHWX9HOdz5GjuYCl2YKl8ZOt4qezxqK63aK/9KPD+7DI3b/I17LM/MrL1MLY9NHa7OPs++bx/Pv8/f///////////////yH5BAEAAB8ALAAAAAAWABYAAAWG4CeOZGmeaKqubOum1SQ/kPVOW749BeVSus2CgrCxHptLBbOQxCSNCCaF1GUqwQbBd0JGJAyGJJiobE+LnCaDcXAaEoxhQACgNw0FQx9kP+wmaRgYFBQNeAoGihCAJQsCkJAKOhgXEw8BLQYciooHf5o7EA+kC40qBKkAAAGrpy+wsbKzIiEAOw==" />
				<img class="intLink" title="Paste" onclick="formatDoc(\'paste\');" src="data:image/gif;base64,R0lGODlhFgAWAIQUAD04KTRLY2tXQF9vj414WZWIbXmOrpqbmpGjudClFaezxsa0cb/I1+3YitHa7PrkIPHvbuPs+/fvrvv8/f///////////////////////////////////////////////yH5BAEAAB8ALAAAAAAWABYAAAWN4CeOZGmeaKqubGsusPvBSyFJjVDs6nJLB0khR4AkBCmfsCGBQAoCwjF5gwquVykSFbwZE+AwIBV0GhFog2EwIDchjwRiQo9E2Fx4XD5R+B0DDAEnBXBhBhN2DgwDAQFjJYVhCQYRfgoIDGiQJAWTCQMRiwwMfgicnVcAAAMOaK+bLAOrtLUyt7i5uiUhADs=" />
				<img class="intLink" title="Remove formatting" onclick="formatDoc(\'removeFormat\')" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAAABGdBTUEAALGPC/xhBQAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAAd0SU1FB9oECQMCKPI8CIIAAAAIdEVYdENvbW1lbnQA9syWvwAAAuhJREFUOMtjYBgFxAB501ZWBvVaL2nHnlmk6mXCJbF69zU+Hz/9fB5O1lx+bg45qhl8/fYr5it3XrP/YWTUvvvk3VeqGXz70TvbJy8+Wv39+2/Hz19/mGwjZzuTYjALuoBv9jImaXHeyD3H7kU8fPj2ICML8z92dlbtMzdeiG3fco7J08foH1kurkm3E9iw54YvKwuTuom+LPt/BgbWf3//sf37/1/c02cCG1lB8f//f95DZx74MTMzshhoSm6szrQ/a6Ir/Z2RkfEjBxuLYFpDiDi6Af///2ckaHBp7+7wmavP5n76+P2ClrLIYl8H9W36auJCbCxM4szMTJac7Kza////R3H1w2cfWAgafPbqs5g7D95++/P1B4+ECK8tAwMDw/1H7159+/7r7ZcvPz4fOHbzEwMDwx8GBgaGnNatfHZx8zqrJ+4VJBh5CQEGOySEua/v3n7hXmqI8WUGBgYGL3vVG7fuPK3i5GD9/fja7ZsMDAzMG/Ze52mZeSj4yu1XEq/ff7W5dvfVAS1lsXc4Db7z8C3r8p7Qjf///2dnZGxlqJuyr3rPqQd/Hhyu7oSpYWScylDQsd3kzvnH738wMDzj5GBN1VIWW4c3KDon7VOvm7S3paB9u5qsU5/x5KUnlY+eexQbkLNsErK61+++VnAJcfkyMTIwffj0QwZbJDKjcETs1Y8evyd48toz8y/ffzv//vPP4veffxpX77z6l5JewHPu8MqTDAwMDLzyrjb/mZm0JcT5Lj+89+Ybm6zz95oMh7s4XbygN3Sluq4Mj5K8iKMgP4f0////fv77//8nLy+7MCcXmyYDAwODS9jM9tcvPypd35pne3ljdjvj26+H2dhYpuENikgfvQeXNmSl3tqepxXsqhXPyc666s+fv1fMdKR3TK72zpix8nTc7bdfhfkEeVbC9KhbK/9iYWHiErbu6MWbY/7//8/4//9/pgOnH6jGVazvFDRtq2VgiBIZrUTIBgCk+ivHvuEKwAAAAABJRU5ErkJggg==">
				<img class="intLink" title="Bold" onclick="formatDoc(\'bold\');" src="data:image/gif;base64,R0lGODlhFgAWAID/AMDAwAAAACH5BAEAAAAALAAAAAAWABYAQAInhI+pa+H9mJy0LhdgtrxzDG5WGFVk6aXqyk6Y9kXvKKNuLbb6zgMFADs=" />
				<img class="intLink" title="Italic" onclick="formatDoc(\'italic\');" src="data:image/gif;base64,R0lGODlhFgAWAKEDAAAAAF9vj5WIbf///yH5BAEAAAMALAAAAAAWABYAAAIjnI+py+0Po5x0gXvruEKHrF2BB1YiCWgbMFIYpsbyTNd2UwAAOw==" />
				<img class="intLink" title="Underline" onclick="formatDoc(\'underline\');" src="data:image/gif;base64,R0lGODlhFgAWAKECAAAAAF9vj////////yH5BAEAAAIALAAAAAAWABYAAAIrlI+py+0Po5zUgAsEzvEeL4Ea15EiJJ5PSqJmuwKBEKgxVuXWtun+DwxCCgA7" />
				<img class="intLink" title="Strike Through" onclick="formatDoc(\'strikeThrough\');" src="data:image/png;base64,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" />
				<img class="intLink" title="Subscript" onclick="formatDoc(\'subscript\', \'hi\');" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAMAAADzapwJAAADAFBMVEX///8AAAD/AAAA/wAAAP8A////AP///wDb29u2traSkpJtbW1JSUkkJCTbAAC2AACSAABtAABJAAAkAAAA2wAAtgAAkgAAbQAASQAAJAAAANsAALYAAJIAAG0AAEkAACQA29sAtrYAkpIAbW0ASUkAJCTbANu2ALaSAJJtAG1JAEkkACTb2wC2tgCSkgBtbQBJSQAkJAD/29vbtra2kpKSbW1tSUlJJCT/trbbkpK2bW2SSUltJCT/kpLbbW22SUmSJCT/bW3bSUm2JCT/SUnbJCT/JCTb/9u227aStpJtkm1JbUkkSSS2/7aS25Jttm1JkkkkbSSS/5Jt221JtkkkkiRt/21J20kktiRJ/0kk2yQk/yTb2/+2ttuSkrZtbZJJSW0kJEm2tv+SktttbbZJSZIkJG2Skv9tbdtJSbYkJJJtbf9JSdskJLZJSf8kJNskJP/b//+229uStrZtkpJJbW0kSUm2//+S29tttrZJkpIkbW2S//9t29tJtrYkkpJt//9J29sktrZJ//8k29sk////2//bttu2kraSbZJtSW1JJEn/tv/bktu2bbaSSZJtJG3/kv/bbdu2SbaSJJL/bf/bSdu2JLb/Sf/bJNv/JP///9vb27a2tpKSkm1tbUlJSST//7bb25K2tm2SkkltbST//5Lb2222tkmSkiT//23b20m2tiT//0nb2yT//yT/27bbtpK2km2SbUltSSRJJAD/tpLbkm22bUmSSSRtJAD/ttvbkra2bZKSSW1tJElJACT/krbbbZK2SW2SJEltACTbtv+2ktuSbbZtSZJJJG0kAEm2kv+SbdttSbZJJJIkAG222/+SttttkrZJbZIkSW0AJEmStv9tkttJbbYkSZIAJG22/9uS27ZttpJJkm0kbUkASSSS/7Zt25JJtm0kkkkAbSTb/7a225KStm1tkklJbSQkSQC2/5KS221ttklJkiQkbQD/tgDbkgC2bQCSSQD/ALbbAJK2AG2SAEkAtv8AktsAbbYASZIAAAD///9tfYS4AAABAHRSTlMA////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Cpf0PAAAAClJREFUGNNjYBgSgBEKsEnh0EG6MKb5jNh1MWI3ixG7DYz47MXuJ3oAABsrABxUFoPSAAAAAElFTkSuQmCC" />
				<img class="intLink" title="Superscript" onclick="formatDoc(\'superscript\', \'hi\');" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAMAAADzapwJAAADAFBMVEX///8AAAD/AAAA/wAAAP8A////AP///wDb29u2traSkpJtbW1JSUkkJCTbAAC2AACSAABtAABJAAAkAAAA2wAAtgAAkgAAbQAASQAAJAAAANsAALYAAJIAAG0AAEkAACQA29sAtrYAkpIAbW0ASUkAJCTbANu2ALaSAJJtAG1JAEkkACTb2wC2tgCSkgBtbQBJSQAkJAD/29vbtra2kpKSbW1tSUlJJCT/trbbkpK2bW2SSUltJCT/kpLbbW22SUmSJCT/bW3bSUm2JCT/SUnbJCT/JCTb/9u227aStpJtkm1JbUkkSSS2/7aS25Jttm1JkkkkbSSS/5Jt221JtkkkkiRt/21J20kktiRJ/0kk2yQk/yTb2/+2ttuSkrZtbZJJSW0kJEm2tv+SktttbbZJSZIkJG2Skv9tbdtJSbYkJJJtbf9JSdskJLZJSf8kJNskJP/b//+229uStrZtkpJJbW0kSUm2//+S29tttrZJkpIkbW2S//9t29tJtrYkkpJt//9J29sktrZJ//8k29sk////2//bttu2kraSbZJtSW1JJEn/tv/bktu2bbaSSZJtJG3/kv/bbdu2SbaSJJL/bf/bSdu2JLb/Sf/bJNv/JP///9vb27a2tpKSkm1tbUlJSST//7bb25K2tm2SkkltbST//5Lb2222tkmSkiT//23b20m2tiT//0nb2yT//yT/27bbtpK2km2SbUltSSRJJAD/tpLbkm22bUmSSSRtJAD/ttvbkra2bZKSSW1tJElJACT/krbbbZK2SW2SJEltACTbtv+2ktuSbbZtSZJJJG0kAEm2kv+SbdttSbZJJJIkAG222/+SttttkrZJbZIkSW0AJEmStv9tkttJbbYkSZIAJG22/9uS27ZttpJJkm0kbUkASSSS/7Zt25JJtm0kkkkAbSTb/7a225KStm1tkklJbSQkSQC2/5KS221ttklJkiQkbQD/tgDbkgC2bQCSSQD/ALbbAJK2AG2SAEkAtv8AktsAbbYASZIAAAD///9tfYS4AAABAHRSTlMA////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Cpf0PAAAACtJREFUGNNjYBhwwMjIiEsGWQ0YoIoiK2LEqpcRu5GM6HYyEnIA9YUHGgAAIQ4AHNvPulcAAAAASUVORK5CYII=" />
				<img class="intLink" title="Horizontal Bar" onclick="formatDoc(\'insertHorizontalRule\');" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAIAAABL1vtsAAADAFBMVEX///8AAAD/AAAA/wAAAP8A////AP///wDb29u2traSkpJtbW1JSUkkJCTbAAC2AACSAABtAABJAAAkAAAA2wAAtgAAkgAAbQAASQAAJAAAANsAALYAAJIAAG0AAEkAACQA29sAtrYAkpIAbW0ASUkAJCTbANu2ALaSAJJtAG1JAEkkACTb2wC2tgCSkgBtbQBJSQAkJAD/29vbtra2kpKSbW1tSUlJJCT/trbbkpK2bW2SSUltJCT/kpLbbW22SUmSJCT/bW3bSUm2JCT/SUnbJCT/JCTb/9u227aStpJtkm1JbUkkSSS2/7aS25Jttm1JkkkkbSSS/5Jt221JtkkkkiRt/21J20kktiRJ/0kk2yQk/yTb2/+2ttuSkrZtbZJJSW0kJEm2tv+SktttbbZJSZIkJG2Skv9tbdtJSbYkJJJtbf9JSdskJLZJSf8kJNskJP/b//+229uStrZtkpJJbW0kSUm2//+S29tttrZJkpIkbW2S//9t29tJtrYkkpJt//9J29sktrZJ//8k29sk////2//bttu2kraSbZJtSW1JJEn/tv/bktu2bbaSSZJtJG3/kv/bbdu2SbaSJJL/bf/bSdu2JLb/Sf/bJNv/JP///9vb27a2tpKSkm1tbUlJSST//7bb25K2tm2SkkltbST//5Lb2222tkmSkiT//23b20m2tiT//0nb2yT//yT/27bbtpK2km2SbUltSSRJJAD/tpLbkm22bUmSSSRtJAD/ttvbkra2bZKSSW1tJElJACT/krbbbZK2SW2SJEltACTbtv+2ktuSbbZtSZJJJG0kAEm2kv+SbdttSbZJJJIkAG222/+SttttkrZJbZIkSW0AJEmStv9tkttJbbYkSZIAJG22/9uS27ZttpJJkm0kbUkASSSS/7Zt25JJtm0kkkkAbSTb/7a225KStm1tkklJbSQkSQC2/5KS221ttklJkiQkbQD/tgDbkgC2bQCSSQD/ALbbAJK2AG2SAEkAtv8AktsAbbYASZIAAAD///9tfYS4AAAABnRSTlMA/wD/AP83WBt9AAAALklEQVQ4y2P8//8/A2WAiYFiMGrEMDSCBUIxMjKSoRmSLIdNWDCOZrNRI2hjBAA5NgknZh65MAAAAABJRU5ErkJggg==" />
				<img class="intLink" title="Left align" onclick="formatDoc(\'justifyleft\');" src="data:image/gif;base64,R0lGODlhFgAWAID/AMDAwAAAACH5BAEAAAAALAAAAAAWABYAQAIghI+py+0Po5y02ouz3jL4D4JMGELkGYxo+qzl4nKyXAAAOw==" />
				<img class="intLink" title="Center align" onclick="formatDoc(\'justifycenter\');" src="data:image/gif;base64,R0lGODlhFgAWAID/AMDAwAAAACH5BAEAAAAALAAAAAAWABYAQAIfhI+py+0Po5y02ouz3jL4D4JOGI7kaZ5Bqn4sycVbAQA7" />
				<img class="intLink" title="Right align" onclick="formatDoc(\'justifyright\');" src="data:image/gif;base64,R0lGODlhFgAWAID/AMDAwAAAACH5BAEAAAAALAAAAAAWABYAQAIghI+py+0Po5y02ouz3jL4D4JQGDLkGYxouqzl43JyVgAAOw==" />
				<img class="intLink" title="Numbered list" onclick="formatDoc(\'insertorderedlist\');" src="data:image/gif;base64,R0lGODlhFgAWAMIGAAAAADljwliE35GjuaezxtHa7P///////yH5BAEAAAcALAAAAAAWABYAAAM2eLrc/jDKSespwjoRFvggCBUBoTFBeq6QIAysQnRHaEOzyaZ07Lu9lUBnC0UGQU1K52s6n5oEADs=" />
				<img class="intLink" title="Dotted list" onclick="formatDoc(\'insertunorderedlist\');" src="data:image/gif;base64,R0lGODlhFgAWAMIGAAAAAB1ChF9vj1iE33mOrqezxv///////yH5BAEAAAcALAAAAAAWABYAAAMyeLrc/jDKSesppNhGRlBAKIZRERBbqm6YtnbfMY7lud64UwiuKnigGQliQuWOyKQykgAAOw==" />
				<img class="intLink" title="Quote" onclick="formatDoc(\'formatblock\',\'blockquote\');" src="data:image/gif;base64,R0lGODlhFgAWAIQXAC1NqjFRjkBgmT9nqUJnsk9xrFJ7u2R9qmKBt1iGzHmOrm6Sz4OXw3Odz4Cl2ZSnw6KxyqO306K63bG70bTB0rDI3bvI4P///////////////////////////////////yH5BAEKAB8ALAAAAAAWABYAAAVP4CeOZGmeaKqubEs2CekkErvEI1zZuOgYFlakECEZFi0GgTGKEBATFmJAVXweVOoKEQgABB9IQDCmrLpjETrQQlhHjINrTq/b7/i8fp8PAQA7" />
				<img class="intLink" title="Pre" onclick="formatDoc(\'formatblock\',\'pre\');" src="data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAIAAABL1vtsAAADAFBMVEX///8AAAD/AAAA/wAAAP8A////AP///wDb29u2traSkpJtbW1JSUkkJCTbAAC2AACSAABtAABJAAAkAAAA2wAAtgAAkgAAbQAASQAAJAAAANsAALYAAJIAAG0AAEkAACQA29sAtrYAkpIAbW0ASUkAJCTbANu2ALaSAJJtAG1JAEkkACTb2wC2tgCSkgBtbQBJSQAkJAD/29vbtra2kpKSbW1tSUlJJCT/trbbkpK2bW2SSUltJCT/kpLbbW22SUmSJCT/bW3bSUm2JCT/SUnbJCT/JCTb/9u227aStpJtkm1JbUkkSSS2/7aS25Jttm1JkkkkbSSS/5Jt221JtkkkkiRt/21J20kktiRJ/0kk2yQk/yTb2/+2ttuSkrZtbZJJSW0kJEm2tv+SktttbbZJSZIkJG2Skv9tbdtJSbYkJJJtbf9JSdskJLZJSf8kJNskJP/b//+229uStrZtkpJJbW0kSUm2//+S29tttrZJkpIkbW2S//9t29tJtrYkkpJt//9J29sktrZJ//8k29sk////2//bttu2kraSbZJtSW1JJEn/tv/bktu2bbaSSZJtJG3/kv/bbdu2SbaSJJL/bf/bSdu2JLb/Sf/bJNv/JP///9vb27a2tpKSkm1tbUlJSST//7bb25K2tm2SkkltbST//5Lb2222tkmSkiT//23b20m2tiT//0nb2yT//yT/27bbtpK2km2SbUltSSRJJAD/tpLbkm22bUmSSSRtJAD/ttvbkra2bZKSSW1tJElJACT/krbbbZK2SW2SJEltACTbtv+2ktuSbbZtSZJJJG0kAEm2kv+SbdttSbZJJJIkAG222/+SttttkrZJbZIkSW0AJEmStv9tkttJbbYkSZIAJG22/9uS27ZttpJJkm0kbUkASSSS/7Zt25JJtm0kkkkAbSTb/7a225KStm1tkklJbSQkSQC2/5KS221ttklJkiQkbQD/tgDbkgC2bQCSSQD/ALbbAJK2AG2SAEkAtv8AktsAbbYASZIAAAD///9tfYS4AAAABnRSTlMA/wD/AP83WBt9AAAAYElEQVQ4y+2TwQ4AEAxDtf//z3OQiFAl4SR2a7Y+jYGISGfFdFyPIwAYuUZIg6FQjnabLnJGuX0XMsIyCHf8noLWU9sjyLQ4nmOWKjNSpm1t3q83UkaroZPiyfzP/h4iAwq5OSE59RfLAAAAAElFTkSuQmCC" />
				<img class="intLink" title="Delete indentation" onclick="formatDoc(\'outdent\');" src="data:image/gif;base64,R0lGODlhFgAWAMIHAAAAADljwliE35GjuaezxtDV3NHa7P///yH5BAEAAAcALAAAAAAWABYAAAM2eLrc/jDKCQG9F2i7u8agQgyK1z2EIBil+TWqEMxhMczsYVJ3e4ahk+sFnAgtxSQDqWw6n5cEADs=" />
				<img class="intLink" title="Add indentation" onclick="formatDoc(\'indent\');" src="data:image/gif;base64,R0lGODlhFgAWAOMIAAAAADljwl9vj1iE35GjuaezxtDV3NHa7P///////////////////////////////yH5BAEAAAgALAAAAAAWABYAAAQ7EMlJq704650B/x8gemMpgugwHJNZXodKsO5oqUOgo5KhBwWESyMQsCRDHu9VOyk5TM9zSpFSr9gsJwIAOw==" />
				<img class="intLink" title="Horizontal Line" onclick="formatDoc(\'insertHorizontalRule\');" src="data:image/gif;base64,R0lGODlhFgAWAOMIAAAAADljwl9vj1iE35GjuaezxtDV3NHa7P///////////////////////////////yH5BAEAAAgALAAAAAAWABYAAAQ7EMlJq704650B/x8gemMpgugwHJNZXodKsO5oqUOgo5KhBwWESyMQsCRDHu9VOyk5TM9zSpFSr9gsJwIAOw==" />
				<img class="intLink" title="Hyperlink" onclick="var sLnk=prompt(\'Write the URL here\',\'http:\/\/\');if(sLnk&&sLnk!=\'\'&&sLnk!=\'http://\'){formatDoc(\'createlink\',sLnk)}" src="data:image/gif;base64,R0lGODlhFgAWAOMKAB1ChDRLY19vj3mOrpGjuaezxrCztb/I19Ha7Pv8/f///////////////////////yH5BAEKAA8ALAAAAAAWABYAAARY8MlJq7046827/2BYIQVhHg9pEgVGIklyDEUBy/RlE4FQF4dCj2AQXAiJQDCWQCAEBwIioEMQBgSAFhDAGghGi9XgHAhMNoSZgJkJei33UESv2+/4vD4TAQA7" />
				<img class="intLink" title="Link Image" onclick="var sLnk=prompt(\'Write image URL here\',\'http:\/\/\');if(sLnk&&sLnk!=\'\'&&sLnk!=\'http://\'){formatDoc(\'createlink\',sLnk)}" src="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjxzdmcKICAgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIgogICB4bWxuczpjYz0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbnMjIgogICB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiCiAgIHhtbG5zOnN2Zz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciCiAgIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKICAgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiCiAgIGlkPSJzdmcxNTcyIgogICB3aWR0aD0iMjIiCiAgIGhlaWdodD0iMjIiCiAgIHZlcnNpb249IjEuMSI+CiAgPG1ldGFkYXRhCiAgICAgaWQ9Im1ldGFkYXRhMTU3NiI+CiAgICA8cmRmOlJERj4KICAgICAgPGNjOldvcmsKICAgICAgICAgcmRmOmFib3V0PSIiPgogICAgICAgIDxkYzpmb3JtYXQ+aW1hZ2Uvc3ZnK3htbDwvZGM6Zm9ybWF0PgogICAgICAgIDxkYzp0eXBlCiAgICAgICAgICAgcmRmOnJlc291cmNlPSJodHRwOi8vcHVybC5vcmcvZGMvZGNtaXR5cGUvU3RpbGxJbWFnZSIgLz4KICAgICAgICA8ZGM6dGl0bGU+PC9kYzp0aXRsZT4KICAgICAgPC9jYzpXb3JrPgogICAgPC9yZGY6UkRGPgogIDwvbWV0YWRhdGE+CiAgPGRlZnMKICAgICBpZD0iZGVmczE1NTIiPgogICAgPGxpbmVhckdyYWRpZW50CiAgICAgICBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSIKICAgICAgIGlkPSJHcmFkaWVudDEiCiAgICAgICB5Mj0iMTAwIgogICAgICAgeDI9IjUwIgogICAgICAgeTE9IjQwIgogICAgICAgeDE9IjUwIj4KICAgICAgPHN0b3AKICAgICAgICAgaWQ9InN0b3AxNTQyIgogICAgICAgICBvZmZzZXQ9IjAiCiAgICAgICAgIHN0eWxlPSJzdG9wLWNvbG9yOiNjY2M7c3RvcC1vcGFjaXR5OjEiIC8+CiAgICAgIDxzdG9wCiAgICAgICAgIGlkPSJzdG9wMTU0NCIKICAgICAgICAgb2Zmc2V0PSIwLjciCiAgICAgICAgIHN0eWxlPSJzdG9wLWNvbG9yOiMwMDA7c3RvcC1vcGFjaXR5OjEiIC8+CiAgICA8L2xpbmVhckdyYWRpZW50PgogICAgPGxpbmVhckdyYWRpZW50CiAgICAgICBncmFkaWVudFRyYW5zZm9ybT0ibWF0cml4KDAuMTQ2MjcwMTcsMCwwLDAuMTQ2MjcwMTcsMi45OTUwNDIzLDMuOTE1ODA4OCkiCiAgICAgICBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSIKICAgICAgIGlkPSJHcmFkaWVudDIiCiAgICAgICB5Mj0iNjAiCiAgICAgICB4Mj0iNTAiCiAgICAgICB5MT0iMCIKICAgICAgIHgxPSI1MCI+CiAgICAgIDxzdG9wCiAgICAgICAgIGlkPSJzdG9wMTU0NyIKICAgICAgICAgb2Zmc2V0PSIwLjIiCiAgICAgICAgIHN0eWxlPSJzdG9wLWNvbG9yOiMzMDFEMDA7c3RvcC1vcGFjaXR5OjEiIC8+CiAgICAgIDxzdG9wCiAgICAgICAgIGlkPSJzdG9wMTU0OSIKICAgICAgICAgb2Zmc2V0PSIxIgogICAgICAgICBzdHlsZT0ic3RvcC1jb2xvcjojRkZBQjAwO3N0b3Atb3BhY2l0eToxIiAvPgogICAgPC9saW5lYXJHcmFkaWVudD4KICAgIDxsaW5lYXJHcmFkaWVudAogICAgICAgZ3JhZGllbnRUcmFuc2Zvcm09Im1hdHJpeCgwLjE0NjI3MDE3LDAsMCwwLjE0NjI3MDE3LDIuOTk1MDQyMywzLjkxNTgwODgpIgogICAgICAgeTI9IjEwMCIKICAgICAgIHgyPSI1MCIKICAgICAgIHkxPSI0MCIKICAgICAgIHgxPSI1MCIKICAgICAgIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIgogICAgICAgaWQ9ImxpbmVhckdyYWRpZW50MjE0NCIKICAgICAgIHhsaW5rOmhyZWY9IiNHcmFkaWVudDEiIC8+CiAgICA8bGluZWFyR3JhZGllbnQKICAgICAgIGdyYWRpZW50VHJhbnNmb3JtPSJtYXRyaXgoMC4xNDYyNzAxNywwLDAsMC4xNDYyNzAxNywyLjk5NTA0MjMsMy45MTU4MDg4KSIKICAgICAgIHkyPSIxMDAiCiAgICAgICB4Mj0iNTAiCiAgICAgICB5MT0iNDAiCiAgICAgICB4MT0iNTAiCiAgICAgICBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSIKICAgICAgIGlkPSJsaW5lYXJHcmFkaWVudDIxNDYiCiAgICAgICB4bGluazpocmVmPSIjR3JhZGllbnQxIiAvPgogIDwvZGVmcz4KICA8cGF0aAogICAgIGlkPSJwYXRoMTU1NCIKICAgICBkPSJNIDMuMjg3NTgyNiw3LjI4MDAyMjUgMTQuMjU3ODQ1LDQuNzkzNDI5NyAxNi43NDQ0MzgsMTQuODg2MDcxIDUuNjI3OTA1MywxNy42NjUyMDQgWiIKICAgICBzdHlsZT0iZmlsbDojZWVlZWVlO3N0cm9rZTojOTk5OTk5O3N0cm9rZS13aWR0aDowLjE0NjI3MDE3IiAvPgogIDxwYXRoCiAgICAgaWQ9InBhdGgxNTU2IgogICAgIGQ9Ik0gNC4xNjUyMDM2LDcuODY1MTAzMyAxMy42NzI3NjQsNS42NzEwNTA3IDE1Ljg2NjgxNywxNC4zMDA5OSA2LjIxMjk4NTksMTYuNzg3NTgzIFoiCiAgICAgc3R5bGU9ImZpbGw6dXJsKCNsaW5lYXJHcmFkaWVudDIxNDQpO3N0cm9rZTojNDQ0NDQ0O3N0cm9rZS13aWR0aDowLjE0NjI3MDE3IiAvPgogIDxwYXRoCiAgICAgaWQ9InBhdGgxNTU4IgogICAgIGQ9Ik0gNS43NzQxNzU0LDUuNjcxMDUwNyBIIDE3LjAzNjk3OCBWIDE2LjQ5NTA0MyBIIDUuNzc0MTc1NCBaIgogICAgIHN0eWxlPSJmaWxsOiNlZWVlZWU7c3Ryb2tlOiM5OTk5OTk7c3Ryb2tlLXdpZHRoOjAuMTQ2MjcwMTciIC8+CiAgPHBhdGgKICAgICBpZD0icGF0aDE1NjAiCiAgICAgZD0iTSA2LjY1MTc5NjUsNi41NDg2NzE3IEggMTYuMTU5MzU3IFYgMTUuNjE3NDIyIEggNi42NTE3OTY1IFoiCiAgICAgc3R5bGU9ImZpbGw6dXJsKCNHcmFkaWVudDIpO3N0cm9rZTojNDQ0NDQ0O3N0cm9rZS13aWR0aDowLjE0NjI3MDE3IiAvPgogIDxwYXRoCiAgICAgaWQ9InBhdGgxNTYyIgogICAgIGQ9Im0gNi42NTE3OTY1LDEwLjkzNjc3NiB2IDQuNjgwNjQ2IEggMTYuMTU5MzU3IFYgOS4wMzUyNjQzIGMgMCwwIC0wLjg3NzYyMSwyLjM0MDMyMjcgLTEuOTAxNTEyLDIuNzc5MTMyNyAtMS4zMTY0MzIsMC41ODUwODEgLTEuOTAxNTEyLC0wLjI5MjU0IC0yLjM0MDMyMiwtMS4xNzAxNjEgLTAuNTg1MDgxLDEuMTcwMTYxIC0wLjczMTM1MSwxLjc1NTI0MiAtMS42MDg5NzMsMi4wNDc3ODMgQyA5LjQzMDkyOTYsMTIuOTg0NTU5IDguNTUzMzA4NiwxMC40OTc5NjYgOC4yNjA3NjgzLDkuNDc0MDc0MyA3LjY3NTY4NzYsMTAuMjA1NDI1IDcuMjM2ODc3MSwxMC43OTA1MDYgNi42NTE3OTY1LDEwLjkzNjc3NiBaIgogICAgIHN0eWxlPSJmaWxsOnVybCgjbGluZWFyR3JhZGllbnQyMTQ2KTtzdHJva2U6IzY2NjY2NjtzdHJva2Utd2lkdGg6MC4xNDYyNzAxNyIgLz4KICA8cGF0aAogICAgIGlkPSJwYXRoMTU2NCIKICAgICBkPSJtIDEzLjY3Mjc2NCwxMy43MTU5MDkgYyAwLDAgMy45NDkyOTUsMi42MzI4NjMgMy42NTY3NTQsNC41MzQzNzYgLTEuNzU1MjQyLDAuMjkyNTQgLTQuNjgwNjQ1LC0zLjY1Njc1NCAtNC42ODA2NDUsLTMuNjU2NzU0IgogICAgIHN0eWxlPSJmaWxsOiM2NjY2NjY7c3Ryb2tlOiMyMjIyMjI7c3Ryb2tlLXdpZHRoOjAuMjkyNTQwMzQiIC8+CiAgPGNpcmNsZQogICAgIGlkPSJjaXJjbGUxNTY2IgogICAgIHN0eWxlPSJmaWxsOm5vbmU7c3Ryb2tlOiMxMTExMTE7c3Ryb2tlLXdpZHRoOjAuMjkyNTQwMzQiCiAgICAgcj0iMy44MDMwMjQzIgogICAgIGN5PSIxMS4zNzU1ODciCiAgICAgY3g9IjEwLjQ1NDgyMiIgLz4KICA8Y2lyY2xlCiAgICAgaWQ9ImNpcmNsZTE1NjgiCiAgICAgc3R5bGU9ImZpbGw6bm9uZTtzdHJva2U6I2JiYmJiYjtzdHJva2Utd2lkdGg6MC41ODUwODA2OCIKICAgICByPSIzLjM2NDIxMzciCiAgICAgY3k9IjExLjM3NTU4NyIKICAgICBjeD0iMTAuNDU0ODIyIiAvPgogIDxjaXJjbGUKICAgICBpZD0iY2lyY2xlMTU3MCIKICAgICBzdHlsZT0iZmlsbDojZWVlZWVlO2ZpbGwtb3BhY2l0eTowLjQ7c3Ryb2tlOiMxMTExMTE7c3Ryb2tlLXdpZHRoOjAuMTQ2MjcwMTciCiAgICAgcj0iMy4wNzE2NzM0IgogICAgIGN5PSIxMS4zNzU1ODciCiAgICAgY3g9IjEwLjQ1NDgyMiIgLz4KPC9zdmc+Cg==" />
				<input type="file" id="imagesUpload" style="display: none;" multiple onchange="imageUpload.call(this, event)" />
				<img class="intLink" title="Image Upload" onclick="document.getElementById(\'imagesUpload\').click();" src="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjxzdmcKICAgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIgogICB4bWxuczpjYz0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbnMjIgogICB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiCiAgIHhtbG5zOnN2Zz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciCiAgIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKICAgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiCiAgIGlkPSJzdmc5NjQiCiAgIHdpZHRoPSIyMiIKICAgaGVpZ2h0PSIyMiIKICAgdmVyc2lvbj0iMS4xIj4KICA8bWV0YWRhdGEKICAgICBpZD0ibWV0YWRhdGE5NjgiPgogICAgPHJkZjpSREY+CiAgICAgIDxjYzpXb3JrCiAgICAgICAgIHJkZjphYm91dD0iIj4KICAgICAgICA8ZGM6Zm9ybWF0PmltYWdlL3N2Zyt4bWw8L2RjOmZvcm1hdD4KICAgICAgICA8ZGM6dHlwZQogICAgICAgICAgIHJkZjpyZXNvdXJjZT0iaHR0cDovL3B1cmwub3JnL2RjL2RjbWl0eXBlL1N0aWxsSW1hZ2UiIC8+CiAgICAgICAgPGRjOnRpdGxlPjwvZGM6dGl0bGU+CiAgICAgIDwvY2M6V29yaz4KICAgIDwvcmRmOlJERj4KICA8L21ldGFkYXRhPgogIDxkZWZzCiAgICAgaWQ9ImRlZnM5NTIiPgogICAgPGxpbmVhckdyYWRpZW50CiAgICAgICBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSIKICAgICAgIGlkPSJHcmFkaWVudDEiCiAgICAgICB5Mj0iMTAwIgogICAgICAgeDI9IjUwIgogICAgICAgeTE9IjQwIgogICAgICAgeDE9IjUwIj4KICAgICAgPHN0b3AKICAgICAgICAgaWQ9InN0b3A5NDIiCiAgICAgICAgIG9mZnNldD0iMCIKICAgICAgICAgc3R5bGU9InN0b3AtY29sb3I6I2NjYztzdG9wLW9wYWNpdHk6MSIgLz4KICAgICAgPHN0b3AKICAgICAgICAgaWQ9InN0b3A5NDQiCiAgICAgICAgIG9mZnNldD0iMC43IgogICAgICAgICBzdHlsZT0ic3RvcC1jb2xvcjojMDAwO3N0b3Atb3BhY2l0eToxIiAvPgogICAgPC9saW5lYXJHcmFkaWVudD4KICAgIDxsaW5lYXJHcmFkaWVudAogICAgICAgZ3JhZGllbnRUcmFuc2Zvcm09Im1hdHJpeCgwLjE1NzcxMzEsMCwwLDAuMTQ2NTA3NjEsMi43NzA3NTc0LDMuNDU4NjU5NikiCiAgICAgICBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSIKICAgICAgIGlkPSJHcmFkaWVudDIiCiAgICAgICB5Mj0iNjAiCiAgICAgICB4Mj0iNTAiCiAgICAgICB5MT0iMCIKICAgICAgIHgxPSI1MCI+CiAgICAgIDxzdG9wCiAgICAgICAgIGlkPSJzdG9wOTQ3IgogICAgICAgICBvZmZzZXQ9IjAuMiIKICAgICAgICAgc3R5bGU9InN0b3AtY29sb3I6IzMwMUQwMDtzdG9wLW9wYWNpdHk6MSIgLz4KICAgICAgPHN0b3AKICAgICAgICAgaWQ9InN0b3A5NDkiCiAgICAgICAgIG9mZnNldD0iMSIKICAgICAgICAgc3R5bGU9InN0b3AtY29sb3I6I0ZGQUIwMDtzdG9wLW9wYWNpdHk6MSIgLz4KICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICA8bGluZWFyR3JhZGllbnQKICAgICAgIGdyYWRpZW50VHJhbnNmb3JtPSJtYXRyaXgoMC4xNTc3MTMxLDAsMCwwLjE0NjUwNzYxLDIuNzcwNzU3NCwzLjQ1ODY1OTYpIgogICAgICAgeTI9IjEwMCIKICAgICAgIHgyPSI1MCIKICAgICAgIHkxPSI0MCIKICAgICAgIHgxPSI1MCIKICAgICAgIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIgogICAgICAgaWQ9ImxpbmVhckdyYWRpZW50MjEyMSIKICAgICAgIHhsaW5rOmhyZWY9IiNHcmFkaWVudDEiIC8+CiAgICA8bGluZWFyR3JhZGllbnQKICAgICAgIGdyYWRpZW50VHJhbnNmb3JtPSJtYXRyaXgoMC4xNTc3MTMxLDAsMCwwLjE0NjUwNzYxLDIuNzcwNzU3NCwzLjQ1ODY1OTYpIgogICAgICAgeTI9IjEwMCIKICAgICAgIHgyPSI1MCIKICAgICAgIHkxPSI0MCIKICAgICAgIHgxPSI1MCIKICAgICAgIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIgogICAgICAgaWQ9ImxpbmVhckdyYWRpZW50MjEyMyIKICAgICAgIHhsaW5rOmhyZWY9IiNHcmFkaWVudDEiIC8+CiAgPC9kZWZzPgogIDxwYXRoCiAgICAgaWQ9InBhdGg5NTQiCiAgICAgZD0iTSAzLjA4NjE4MzYsNi44MjgzMzQ2IDE0LjkxNDY2NSw0LjMzNzcwNDkgMTcuNTk1Nzg4LDE0LjQ0NjczIDUuNjA5NTkzMiwxNy4yMzAzNzYgWiIKICAgICBzdHlsZT0iZmlsbDojZWVlZWVlO3N0cm9rZTojOTk5OTk5O3N0cm9rZS13aWR0aDowLjE1MjAwNzEzIiAvPgogIDxwYXRoCiAgICAgaWQ9InBhdGg5NTYiCiAgICAgZD0iTSA0LjAzMjQ2MjIsNy40MTQzNjUgMTQuMjgzODE0LDUuMjE2NzUwOCAxNi42NDk1MTEsMTMuODYwNyA2LjI0MDQ0NTgsMTYuMzUxMzI5IFoiCiAgICAgc3R5bGU9ImZpbGw6dXJsKCNsaW5lYXJHcmFkaWVudDIxMjEpO3N0cm9rZTojNDQ0NDQ0O3N0cm9rZS13aWR0aDowLjE1MjAwNzEzIiAvPgogIDxwYXRoCiAgICAgaWQ9InBhdGg5NTgiCiAgICAgZD0iTSA1Ljc2NzMwNjQsNS4yMTY3NTA4IEggMTcuOTExMjE1IFYgMTYuMDU4MzE0IEggNS43NjczMDY0IFoiCiAgICAgc3R5bGU9ImZpbGw6I2VlZWVlZTtzdHJva2U6Izk5OTk5OTtzdHJva2Utd2lkdGg6MC4xNTIwMDcxMyIgLz4KICA8cGF0aAogICAgIGlkPSJwYXRoOTYwIgogICAgIGQ9Ik0gNi43MTM1ODUsNi4wOTU3OTY1IEggMTYuOTY0OTM2IFYgMTUuMTc5MjY5IEggNi43MTM1ODUgWiIKICAgICBzdHlsZT0iZmlsbDp1cmwoI0dyYWRpZW50Mik7c3Ryb2tlOiM0NDQ0NDQ7c3Ryb2tlLXdpZHRoOjAuMTUyMDA3MTMiIC8+CiAgPHBhdGgKICAgICBpZD0icGF0aDk2MiIKICAgICBkPSJtIDYuNzEzNTg1LDEwLjQ5MTAyNSB2IDQuNjg4MjQ0IEggMTYuOTY0OTM2IFYgOC41ODY0MjU5IGMgMCwwIC0wLjk0NjI3OCwyLjM0NDEyMjEgLTIuMDUwMjcxLDIuNzgzNjQ1MSAtMS40MTk0MTcsMC41ODYwMyAtMi4wNTAyNjksLTAuMjkzMDE2IC0yLjUyMzQwOSwtMS4xNzIwNjEgLTAuNjMwODUyLDEuMTcyMDYxIC0wLjc4ODU2NSwxLjc1ODA5MSAtMS43MzQ4NDQsMi4wNTExMDYgQyA5LjcxMDEzMzgsMTIuNTQyMTMyIDguNzYzODU1NCwxMC4wNTE1MDIgOC40NDg0MjkyLDkuMDI1OTQ4OCA3LjgxNzU3NjcsOS43NTg0ODY4IDcuMzQ0NDM3NSwxMC4zNDQ1MTcgNi43MTM1ODUsMTAuNDkxMDI1IFoiCiAgICAgc3R5bGU9ImZpbGw6dXJsKCNsaW5lYXJHcmFkaWVudDIxMjMpO3N0cm9rZTojNjY2NjY2O3N0cm9rZS13aWR0aDowLjE1MjAwNzEzIiAvPgo8L3N2Zz4K" />
				<input type="file" id="cameraUpload" style="display: none;" capture="environment" onchange="imageUpload.call(this, event)" />
				<img class="intLink" title="Camera Pictures" onclick="document.getElementById(\'cameraUpload\').click();" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAWCAYAAADEtGw7AAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw1AUhU9TpSKVDu0g4pChOlkQFXHUKhShQqgVWnUweekfNGlIUlwcBdeCgz+LVQcXZ10dXAVB8AfEydFJ0UVKvC8ptIjxwiMf591z8t59gNCsMs3qGQc03TYzqaSYy6+KoVcEEEUEQEBmljEnSWn41tc9dVPdJXiWf9+fNaAWLEa/EYlnmWHaxBvE05u2wXmfOMbKskp8Tjxm0gGJH7muePzGueSywDNjZjYzTxwjFktdrHQxK5sa8RRxXNV0yhdyHquctzhr1Tprn5PfMFzQV5a5TmsYKSxiCRJEKKijgipsJOirk2IhQ/tJH/+Q65fIpZCrAkaOBdSgQXb94G/we7ZWcXLCSwongd4Xx/kYAUK7QKvhON/HjtM6AYLPwJXe8deawMwn6Y2OFj8CItvAxXVHU/aAyx1g8MmQTdmVgrSEYhF4P6NnygPRW6B/zZtbex+nD0CWZpW+AQ4OgdESZa/73Luve27/9rTn9wPEWnJhw2mVdgAAAAZiS0dEAP8A/wD/oL2nkwAAA3hJREFUOMvtlM1rXGUUxn/ve++dOzcfk0ymk8lMomltUrW1ai2WqTbSliooIkRBF1oXCtqNoLhVwS7iQlpQsKALKbjQomlXWgihVin9oraWtkk039/JTE2TGTMzd+7ce1w0bRGK/gN54MCBw3k4POc5B1axAvU/dfuVd757oamhJW1ZVrjk5jNj2ZHxqezYT793d2X+q9G8lXz9rajGGNqtYADqpeeUW82uznk3d6CYn0gppdBKI1W1mMXKAaALWBjNiVoXUXLXiY/+KMZCjo1DM3MbJ2cH2vAKkdraNcOnfz3c2TeV2VW5d6tdFU/h+h7+xBWai5MT6a3P7I8m1o6VLvdZ8Qcfrk9s2DLWmIxdeeNFtXyb+OQpiXSfmvjg4sWeVy+NnEsWlhdprjJlKbpZNz3eiaPDeLMjGI6Dkbqf2ZFzWNe6l+TsmWKs6xOx82606S99qa2p/d3P9j96/rYUFwaJjA6ff3Jy+GyqMDsIfp7puj1q01N7aa+N03/iKP7x74nZV3FbO2h9+SMmUHWZs0fqatcmyM8v0H+yO3Xmq+M1nV+KOva2EhNg/vpIVMpLMaQI5TI4Mdj8LDtaEpgFn6HSMn6liEgD1X3HKP2cIrnjdbzOLv588z3wKqj2Rl1K16ieyx8DoAG00qA1KA1+GRrX8VA8ybmR63zT20NmvI9I2EX7FQJasQZ7MQpLmE4DtCYg4YARtjAbQphb9B1XiNwMBLSgq2twSx75yd+oGjhFfK4fx11ErbhTFVykVEQphTIsRHwwnCodjldDg7o9MaKEFV4MiyA7g7JsnGCOlux56nJZtKiVXfv4sSQqEqfilZHi3zdpRCAIRPlyRwohkCDwEQnADMHcH2RmrhFev53QpjSKRaAMlIAx/N3vc8PzyM8PgJu7KSMQiFAJ5M6BROubcgTBongBiIKaGhZ/+YLs8x/SuPst7PVpdG4KROHd9wT5UD2ZC0fw+k+DbYEIUa0LzU54+elHOoKDt4j37a2aGx16oHtwYiDB8Og9FPOAL9OHdpamd35qRTemQ368TdkIS5lxyhcOeVztFfABUxNJuts6tl/c0L5l7OA+HfzrV3x+2G26cX1mm6HVVqVUGKWMkBV+TBtmy3R2sjqfX0gobbqpNc0n7JA9rhBHUIgERdOwQrZTe8W2wz/se82YXX3Bq7g7/gG+v3o1H14mHQAAAABJRU5ErkJggg==" />
	</div>
	<div id="content1" contenteditable="true">' . $content_text . '</div>
	<p id="editMode">
		<input type="checkbox" name="switchMode" id="switchBox" onchange="setDocMode(this.checked);" />
		<label for="switchBox">Show HTML</label>
		</p>';
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
			my @finalEntries = split(/~/, $_);
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
		my @finalEntries = split(/~/, $entries[$i]);
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
	<link rel="shortcut icon" 				type="image/png" href="favicon.png" />
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
<body">
	<div id=all>
	<div id=top>
		<img src="app/media/logo.png" style="position: absolute; left: 10px;"/><h2><center>'.$config->{metaDescription}.'</center></h2>
		 <a style="padding-left: 200px;" href="about_me.html">About Me</a> - <a href="help.html">Help</a>
		<div class="topbar">
			<form accept-charset="UTF-8"   name="form1" method="post">
				<input type="text" pattern=".{3,20}" required title="Must be at least 3 characters" name="keyword" placeholder="Search terms">
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
';
#print '<h1>Latest Entries</h1>';

#my @entriesOnMenu = getFiles($config->{postsDatabaseFolder});
#my $i = 0;
#foreach(@entriesOnMenu)
#{
	#if($i <= $config->{menuEntriesLimit})
	#{
		#my @entry = split(/~/, $_);
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
	my @data = split(/~/, $content);
	my $title = $data[0];
	print '<a href="?viewDetailed='.$fileName.'">'.$title.'</a>';
}

print '<h1><center>Categories</center></h1>';			# Show Categories on Menu	THIS IS THE MENU SECTION
print '<a href=?page=1 >- All Categories  -</a>';
my @categories = sort(getCategories());
foreach(@categories)
{
	print '<a href="?viewCat='.$_.'">'.$_.'</a>';
}
#print 'No categories yet.' if scalar(@categories) == 0;
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
			my @entry = split(/~/, $_);
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
			<tr>
				<td>Admin Password:</td>
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
		#<form name="compForm" method="post" action="sample.php" onsubmit="if(validateMode()){this.myDoc.value=oDoc.innerHTML;return true;}return false;">
		print '<h1>Making New Post</h1>

		<form accept-charset="UTF-8"  id="submitform" action="" name="submitform" method="post">
		<input type="hidden" id="actual_content" name="content" />
		Title
		<input name="title" type="text" pattern=".{3,20}" required title="Must be at least 3 characters long (only letters and numbers)" id=title>
		';
		printTextEditor('');
		print '
		<input type="checkbox" name="isPage" value="1">
		Make Headline not Post<a href="javascript:alert(\'Add to the main menu HEADLINE section, but do not make visibile when listing posts (however can be found by searching)\')">(?)</a>
		<br />
		<input name="category" type="text" pattern="([A-Za-z0-9]){3,20}" required title="Must be at least 3 characters long (only letters and numbers)" id="category"> Category
		';
		#print '(Available:
		#<br />';
		#if($config->{useHtmlOnEntries} == 0)
		#{
			#print '
				#&nbsp;
				#<input type="button" style="width:50px;font-weight:bold;" onClick="surroundText(\'[b]\', \'[/b]\', document.forms.submitform.content); return false;" value="b" />
				#<input type="button" style="width:50px;font-style:italic;" onClick="surroundText(\'[i]\', \'[/i]\', document.forms.submitform.content); return false;" value="i" />
				#<input type="button" style="width:50px;text-decoration:underline;" onClick="surroundText(\'[u]\', \'[/u]\', document.forms.submitform.content); return false;" value="u" />
				#<input type="button" style="width:50px;" onClick="surroundText(\'[url]\', \'[/url]\', document.forms.submitform.content); return false;" value="url" />
				#<input type="button" style="width:50px;" onClick="surroundText(\'[img]\', \'[/img]\', document.forms.submitform.content); return false;" value="img" />
				#<input type="button" style="width:50px;" onClick="surroundText(\'[code]\', \'[/code]\', document.forms.submitform.content); return false;" value="code" />
			#<br />';
		#print 'Content<br />(You can use BBCODE)<br />
			#<!-- <a href="?do=showSmilies" target="_blank">Show Smilies</a><br />-->
			#<img src="'.$config->{smiliesFolder}.'/worried.gif">:worried:<br />
			#<img src="'.$config->{smiliesFolder}.'/n_n.png">:n_n:<br />
			#<img src="'.$config->{smiliesFolder}.'/happy.gif">:happy:<br />
			#<img src="'.$config->{smiliesFolder}.'/doh.gif">:doh:<br />
			#<img src="'.$config->{smiliesFolder}.'/cry.png">:cry:<br />
			#<img src="'.$config->{smiliesFolder}.'/cool.gif">:cool:
		# ';
		#}
		#else
		#{
			#print '<script src="app/nicEdit.js" type="text/javascript"></script>
			#<script type="text/javascript">bkLib.onDomLoaded(nicEditors.allTextAreas);</script>' if($config->{useWYSIWYG} == 1);
			#print '';
		#}

		#my $i = 1;
		#foreach(@categories)
		#{
			#if($i < scalar(@categories))	# Here we display a comma between categories so is easier to undesrtand
			#{
				#print $_.', ';
			#}
			#else
			#{
				#print $_;
			#}
			#$i++;
		#}
		#print ')';
		print '<br />
		<input name="pass" type="password" id="pass"> Admin Password
		<input name="process" type="hidden" id="process" value="newEntry">
		<br />

		&nbsp;
		<input type="submit" name="Submit" value="Add Post" onclick="document.getElementById(\'actual_content\').value = document.getElementById(\'content1\').innerHTML;" />
		<br />
		</form>
		<script src="app/blog.js" type="text/javascript"></script>
		';
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
        #if($config->{useHtmlOnEntries} == 0)
        #{
            #$content = bbcode(r('content'));
        #}
        #else
        #{
            #$content = basic_r('content');
        #}
		$content = basic_r('content');
        my $category = r('category');
        my $isPage = r('isPage');

        if($title eq '' || $content eq '' || $category eq '')
        {
            die("All fields are neccesary!");
        }

        if($pass eq $config->{adminPass})
        {
         my @files = getFiles($config->{postsDatabaseFolder});
         my @lastOne = split(/~/, $files[0]);
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
         print FILE $title.'~'.$content.'~'.$date.'~'.$category.'~'.$i;    # 0: Title, 1: Content, 2: Date, 3: Category, 4: FileName
         print 'Your post <b>'.$title.'</b> has been saved. <a href="?page=1">Go to Index</a><script>window.location ="?page=1";</script>';
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
		my @split = split(/~/, $_);											# [0] = Title	[1] = Content	[2] = Date	[3] = Category
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
			my @finalEntries = split(/~/, $thisCategoryEntries[$i]);
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
				print '<div class="post posthighlevel">';
				if ($#entries < 1 && $finalEntries[2] != '' )
				{
					print '<div class="postinfo">
						<i>Posted on '.$finalEntries[2].' in Category: <a href="?viewCat='.$finalEntries[3].'">'.$finalEntries[3].'</a>
							<br />
							<div class="right">
								<button onclick="window.location=\'?viewDetailed='.$finalEntries[4].'\'">View Post</button>
								<!--<button onclick="window.location=\'?edit='.$finalEntries[4].'\'">Edit</button>
								<button onclick="window.location=\'?delete='.$finalEntries[4].'\'">Delete</button>-->
							</div></i>
					</div>';
				}

				print '<h1><a href="?viewDetailed='.$finalEntries[4].'">'.$finalEntries[0].'</a></h1>
					<div class="entry">'
						.$finalEntries[1].'
					</div>
					<br />
					<br />
				</div>';
					#<div class="postinfo">
						#<br /><div class="right"><a href="?viewDetailed='.$finalEntries[4].'">Comments</a><!-- - <a href="?edit='.$finalEntries[4].'">Edit</a> - <a href="?delete='.$finalEntries[4].'">Delete</a>--></div></i>
					#</div>
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
	print '<h1>Edit Post</h1>
	<form accept-charset="UTF-8"   name="form1" method="post">
	<table>
		<tr>
			<td>Admin Password</td>
			<td><input name="pass" type="password" id="pass">
			<input name="process" type="hidden" id="process" value="editSecured">
			<input name="fileName" type="hidden" id="fileName" value="'.$fileName.'"></td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td><input type="submit" name="Submit" value="Add / Edit Content" onclick="document.getElementById(\'actual_content\').value = document.getElementById(\'content1\').innerHTML;" /></td>
		</tr>
	</table>
	</form>
	<script src="app/blog.js" type="text/javascript"></script>
	';
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
		my @entry = split(/~/, $tempContent);
		my $fileName = $entry[4];
		my $title = $entry[0];
		my $content = $entry[1];
		my $category = $entry[3];
		print '<h1>Editing Post</h1>
		<form accept-charset="UTF-8"   action="" name="submitform" method="post">
			<input type="hidden" id="actual_content" name="content" /><br />
			Title: <input name=title type=text id=title value="'.$title.'">';
		#if($config->{useHtmlOnEntries} == 0)
		#{
			#print bbdecode($content);
		#}
		#else
		#{
			#print $content;
		#}
		printTextEditor($content);
		print 'Category: <input name="category" type="text" pattern="([A-Za-z0-9]){3,20}" required title="Must be at least 3 characters long (only letters and numbers)" id="category" value="'.$category.'"><br />
		Admin Password: <input name="pass" type="password" id="pass">
			<input name="process" type="hidden" id="process" value="editEntry">
			<input name="fileName" type="hidden" id="fileName" value="'.$fileName.'">
			<br />
			<input type="submit" name="Submit" value="Save Edits" onclick="document.getElementById(\'actual_content\').value = document.getElementById(\'content1\').innerHTML;" />
		</form>
		(Available Categories: ';
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
		print ')
		<script src="app/blog.js" type="text/javascript"></script>
		';
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
		#if($config->{useHtmlOnEntries} == 0)
		#{
			#$content = bbcode(r('content'));
		#}
		#else
		#{
			#$content = basic_r('content');
		#}
		$content = basic_r('content');
		my $category = r('category');
		my $fileName = r('fileName');

		open(FILE, "+>$config->{postsDatabaseFolder}/$fileName.$config->{dbFilesExtension}");

		if($title eq '' or $content eq '' or $category eq '')
		{
			die("All fields are neccesary! title=" . $title . " content=" . $content . " category=" . $category);
		}

		my $date = getdate($config->{gmt});
		print FILE $title.'~'.$content.'~'.$date.'~'.$category.'~'.$fileName;	# 0: Title, 1: Content, 2: Date, 3: Category, 4: FileName
		print 'Your post '.$title.' has been edited. <a href="?viewDetailed='.$fileName.'">Go Back</a><script>window.location ="?page=1";</script>';
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
	print '<h1>Delete Post</h1>
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
		print 'Entry deleted. <a href="?page=1">Go to Index</a><script>window.location ="?page=1";</script>';
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
			my @currEntry = split(/~/, $_);
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
		my @entry = split(/~/, $tempContent);
		my $fileName = $entry[4];
		my $title = $entry[0];
		my $content = $entry[1];
		my $category = $entry[3];
		print '<i style="float : right; font-size : .8em;">'.$entry[2] . '</i>
			<h1>'.$entry[0].'</h1>
			<div class="postinfo" style="text-align : right;">
				<i>Category: <a href="?viewCat='.$entry[3].'">'.$entry[3].'</a>
				<br />
				<div>
					<button onclick="window.location=\'?edit='.$entry[4].'\'">Edit</button>
					<button onclick="window.location=\'?delete='.$entry[4].'\'">Delete</button>
				</div>
			</div>
			'.$entry[1].'<br /><br />
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

		print '<h1>Comments For This Post:</h1>
			<button style="float: right;" onclick="document. getElementsByClassName(\'addcomment\')[0].style.display =\'block\';">Add comment</button>
			<br />
		';
		if($content eq '')
		{
			print '<p>No comments posted yet</p>';
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
				my @comment = split(/~/, $_);
				my $title = $comment[0];
				my $author = $comment[1];
				my $content = $comment[2];
				my $date = $comment[3];
				print '<div class="comment">
				<span style="font-size : .8em; float: right;">By <b>'.$author.'</b> - <i>'.$date.'</i></span>
				<span><b>'.$title.'</b></span>
				<br />
				<br />';
				#if($config->{bbCodeOnCommentaries} == 0)
				#{
					#print txt2html($content);
				#}
				#else
				#{
					#print bbcode($content);
				#}
				print txt2html($content);
				$i++;	# This is used for Deleting comments, to i know what comment number is it :]

				print '<button style="float : right;" onclick="window.location=\'?deleteComment='.$fileName.'.'.$i.'\'">Delete</button>
				</div>'
			}
		}
		# Add comment form
		if($config->{allowComments} == 1)
		{
			print '<br /><br /><div class="addcomment"><h1 style="text-align: right;">Add Comment</h1>
			<form accept-charset="UTF-8"   name="submitform" method="post" style="margin-left: 2em;">
				<input name="sendComment" value="'.$fileName.'" type="hidden" id="sendComment">
				<input type="hidden" id="actual_content" name="content" />
				<table style="width : 100%;">
					<tr>
						<td>Comment Title</td>
						<td><input name="title" type="text" pattern=".{3,20}" required title="Must be at least 3 characters long" id="title"></td>
					</tr>
					<tr>
					<td>Content<br /><a href="?do=showSmilies" target="_blank">Show Smilies</a></td>
					<td>';
					printTextEditor('');
					print '</td>
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
				<td><input size="8" name="code" type="text" pattern="([A-Za-z0-9]){3,20}" required title="Must be at least 3 characters long (only letters and numbers)" id="code"> &nbsp;  &nbsp;  &nbsp;  (Used to verify human)</td>
				</tr>';
			}

			print '<tr>
				<td>'.$config->{commentsSecurityQuestion}.'</td>
				<td><input size="8" name="question" type="text" pattern="([A-Za-z0-9]){3,20}" required title="Must be at least 3 characters long (only letters and numbers)" id="question">
				 &nbsp;  &nbsp;  &nbsp; (Get answer from admin)</td>
				 </td>
			</tr>
			<tr>' if $config->{securityQuestionOnComments} == 1;

			print '			<tr>
				<td>Your Name</td>
				<td><input size="8" name="author" type="text" pattern="([A-Za-z0-9]){3,20}" required title="Must be at least 3 characters long (only letters and numbers)" id="author"></td>
			</tr>
			<tr>
				<td>Your Password</td>
				<td><input size="8" name="pass" type="password" id="pass"> &nbsp; &nbsp; &nbsp; (Created on first comment)</td>
			</tr>
			<tr>
				<td>&nbsp;</td>
				<td>
					<input type="submit" name="Submit" value="Add Post" onclick="document.getElementById(\'actual_content\').value = document.getElementById(\'content1\').innerHTML;" />
				</td>
			</tr>
			</table>
			</form>
			<script src="app/blog.js" type="text/javascript"></script>
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
	my $content = basic_r('content');
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
		my @users = split(/~/, $data);
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
		print 'Your first comment was added.  The name and password you entered will be remembered.  Please use this same name and password when creating future comments.<br>';
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
				my $content = $title.'~'.$author.'~'.$content.'~'.$date.'~'.$fileName."'";

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
					print MAIL "Subject: New Comment on your pBlog Blog\n\n";
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

	print '<h1>Deelte Comment</h1>
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
	my @dates = map { split(/~/, $_); @_[2].'|'.@_[4].'|'.@_[0]; } @entries;
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
			<tr>
				<th><i>Title</i></th>
				<th>Date</th>
				<th><i>Author</i></th>
			</tr>
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
			my @finalEntries = split(/~/, $comments[$i]);
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
				print '<tr>
				<td><a href="?viewDetailed='.$finalEntries[4].'">'.$finalEntries[0].'</a></td>
				<td> '.$finalEntries[3].'</td>
				<td style="text-transform: capitalize;"><b>'.$finalEntries[1].'</b></td>
				</tr>';
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
				my @finalEntries = split(/~/, $entries[$i]);
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

					print '<div class="post posthighlevel">';
					if ($#entries < 1 && $finalEntries[2] != '' )
					{
						print '<div class="postinfo">
							<i>Posted on '.$finalEntries[2].' in Category: <a href="?viewCat='.$finalEntries[3].'">'.$finalEntries[3].'</a>
								<br />
								<div class="right">
									<button onclick="window.location=\'?viewDetailed='.$finalEntries[4].'\'">View Post</button>
									<!--<button onclick="window.location=\'?edit='.$finalEntries[4].'\'">Edit</button>
									<button onclick="window.location=\'?delete='.$finalEntries[4].'\'">Delete</button>-->
								</div></i>
						</div>';
					}
					print '
						<a href="?viewDetailed='.$finalEntries[4].'">
						<h1>'.$finalEntries[0].'</h1>
						</a>
						<div class="entry">'
							. $w2 . ' ' . $e . '
						</div>';
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
print '</div><div id="footer">Copyright '.$config->{blogTitle}.' '.$year.' - All Rights Reserved - Powered by <a href="http://pplog.infogami.com/">pBlog</a>'; print '<br>All posts are using GMT '.$config->{gmt} if $config->{showGmtOnFooter} == 1; print '</div></div></body></html>';
}