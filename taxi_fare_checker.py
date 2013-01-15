import sys
import xml.sax
import re
import datetime

def parse_time(time_string):
  pattern = re.compile(
    '([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2}).*Z')
  match = pattern.match(time_string)
  if match:
    t = [int(x) for x in match.groups()]
    return datetime.datetime(t[0], t[1], t[2], t[3], t[4], t[5])

class entry:
  def __init__(self):
    self.lat = -180.0
    self.lon = -200.0
    self.time = datetime.time()
    self.ele = 0.0

class XMLEcho(xml.sax.handler.ContentHandler):
  def __init__(self):
    self._element_stack = []

  def startElement(self, name, attrs):
    self._element_stack.append(name)
    if name == "trkseg":
      self._trkseg = []
    elif name == "trkpt":
      lat = float(attrs["lat"])
      lon = float(attrs["lon"])
      self.trkpt = entry()
      self.trkpt.lat = lat
      self.trkpt.lon = lon
    elif name == "ele" and "trkpt" not in self._element_stack:
      print "Found an elevation outside of a trkpt. Help!"
    elif name == "time" and "trkpt" not in self._element_stack:
      print "Found a time outside of a trkpt. Help!"

  def endElement(self, name):
    self._element_stack.pop()

  def characters(self, content):
    print "Characters"
    print [hex(ord(a)) for a in content]

parser = xml.sax.make_parser()
parser.setContentHandler(XMLEcho())
parser.parse(sys.stdin)
