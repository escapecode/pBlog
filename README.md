# Overview
[![screenshot](https://github.com/escapecode/pBlog/blob/master/screenshots/blog00.jpg)](https://raw.github.com/wiki/escapecode/pBlog/blob/master/screenshots/blog00.jpg)

pBlog is a tiny Blog system which originated from PPLOG (which appears to be defunct).  Use pBlog the same way you use Blogger, Blogspot, Reddit, etc.  Since pBlog runs on your web server, you can restrict access to your blog including if you want it visible on the internet.

## Requirements
Web server that can handle Perl CGI

# Quickstart
[![screenshot](https://github.com/escapecode/pBlog/blob/master/screenshots/blog01.jpg)](https://raw.github.com/wiki/escapecode/pBlog/blob/master/screenshots/blog01.jpg)

1. Download the source and put the contents in a location accessible by your web server's Perl interface
2. Modify app/config.pl to your liking (make sure to change adminPass)
3. Modify about_me.html to your liking
4. In a web browser, navigate to the path where index.pl is located
5. After bringing up pBlog in a browser, use it's help system to start adding blog posts

# License

This add-on is GPLv3 [licensed](http://www.opensource.org/licenses/gpl-3.0.html).

# Contributing

To submit code changes, please open pull requests against [the GitHub repository](https://github.com/escapecode/pBlog/edit/master/README.md). Patches submitted in issues, email, or elsewhere will likely be ignored. Here's some general guidelines when submitting PRs:

 * In your pull request, please:
   * Describe the changes, why they were necessary, etc
   * Describe how the changes affect existing behaviour
   * Describe how you tested and validated your changes
   * Include any relevant screenshots/evidence demonstrating that the changes work and have been tested

# Notes
pBlog was written to eventually replace PPLOG, which is included in Linux distributions such as Puppy Linux
