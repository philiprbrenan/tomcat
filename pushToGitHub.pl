#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Hello world on Tomcat
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2024
#-------------------------------------------------------------------------------
use v5.34;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use GitHub::Crud qw(:all);

makeDieConfess;

my $home  = currentDirectory;                                                   # Local files
my $user  = q(philiprbrenan);                                                   # User
my $repo  = q(tomcat);                                                          # Repo
my $wf    = q(.github/workflows/main.yml);                                      # Work flow on Ubuntu

if (0)                                                                          # Local build
 {say STDERR qx(javac -cp  /home/phil/zz/apache-tomcat-10.1.24/lib/servlet-api.jar -d build/WEB-INF/classes HelloWorldServlet.java);
  say STDERR qx(jar cvf my-webapp.war -C build/ .);
  say STDERR qx(cp my-webapp.war /home/phil/zz/apache-tomcat-10.1.24/webapps/);
  exit;
 }

if (1)                                                                          # Documentation from pod to markdown into read me with well known words expanded
 {push my @files, searchDirectoryTreesForMatchingFiles($home, qw(.java .jsp .xml .pl));

  for my $s(@files)                                                             # Upload each selected file
   {my $c = readFile $s;                                                        # Load file
    my $t = swapFilePrefix $s, $home;
    my $w = writeFileUsingSavedToken($user, $repo, $t, $c);
    lll "$w $s $t";
   }
 }

if (1)
 {my $d = dateTimeStamp;
  my $y = <<"END";
# Test $d

name: Test
run-name: Tomcat

on:
  push:
    paths:
      - '**/main.yml'

concurrency:
  group: \${{ github.workflow }}-\${{ github.ref }}
  cancel-in-progress: true

jobs:

  test:
    permissions: write-all
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout\@v3
      with:
        ref: 'main'

    - name: Install Tree
      run:
        sudo apt install tree unzip

    - name: Download TomCat
      run: |
        curl  -s -o tc.zip https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.24/bin/apache-tomcat-10.1.24.zip

    - name: Unzip TomCat
      run: |
        unzip -q tc.zip
        tree

    - name: Install TomCat
      run: |
        cp -R  apache-tomcat-10.1.24/* .
        rm -rf apache-tomcat-10.1.24/

    - name: Enable TomCat
      run: |
        tree
        chmod u+x bin/*

    - name: 'JDK 22'
      uses: oracle-actions/setup-java\@v1
      with:
        website: jdk.java.net

    - name: Create app
      run: |
        mkdir -p build/WEB-INF/classes
        cp -R web/ build/;

    - name: Compile app
      run: |
        javac -cp  lib/servlet-api.jar -d build/WEB-INF/classes HelloWorldServlet.java

    - name: Compress app
      run: |
        jar cvf my-webapp.war -C build/ .

    - name: Position app
      run: |
        cp my-webapp.war webapps/

    - name: Run tomcat
      run: |
        ./bin/startup.sh
        sleep 2

    - name: Test tomcat static file
      run: |
        curl -s -o z1.html http://localhost:8080/my-webapp/
        cat z1.html

    - name: Test tomcat servlet
      run: |
        curl -s -o z2.html http://localhost:8080/my-webapp/hello
        cat z2.html

    - name: Print log
      run: |
        ls -la logs/localhost.*.log
        cat    logs/localhost.*.log
END

  my $f = writeFileUsingSavedToken $user, $repo, $wf, $y;                       # Upload workflow
  lll "Ubuntu work flow for $repo written to: $f";
 }
