#! /usr/bin/env python
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Author: Brandon Authier (hblkr)
#
#  Date: 4 Dec 2017
#
#  File: host-serve.py
#
#  Syntax: host-serve.py
#
#  Description:
#
#    This script will create a small BaseHTTPServer in python to serve the host
#    html file for viewing.
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

from os import curdir, sep
import os
import sys
import BaseHTTPServer
import httplib

__copyright__ = 'Copyright 2017 Hblkr, LLC'
__author__ = 'Brandon Authier'
__email__ = 'brandon.authier@zonarsystems.com'

PORT_NUMBER = 8080
HOST_NAME = '' # Open to any hostname, could restrict if needed

class MyHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    def do_GET(self):
        self.path = sys.argv[0]
        scriptPath = ""
        pathHolder = sys.argv[0].split("/")

        for x in range(1, (len(pathHolder) - 2)):
            scriptPath += "/" + pathHolder[x]
        scriptPath += "/host-status.html"
        self.path = scriptPath

        try:
            sendReply = False
            if self.path.endswith(".html"):
                mimetype = 'text/html'
                sendReply = True

            if sendReply == True:
                #Open the static file requested and send it
                f = open(curdir + sep + self.path)
                self.send_response(httplib.OK)
                self.send_header('Content-type',mimetype)
                self.end_headers()
                self.wfile.write(f.read())
                f.close()
                return

        except IOError:
            self.send_error(404,'File Not Found: %s' % self.path)

if __name__ == '__main__':
    server_class = BaseHTTPServer.HTTPServer
    httpd = server_class((HOST_NAME, PORT_NUMBER), MyHandler)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
