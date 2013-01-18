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
  def __str__(self):
    return "%s,%s,%s,%s" % (str(self.lat), str(self.lon), str(self.time),
      str(self.ele))
  def __repr__(self):
    return "%s,%s,%s,%s" % (str(self.lat), str(self.lon), str(self.time),
      str(self.ele))

class gpx_parse(xml.sax.handler.ContentHandler):
  def __init__(self):
    self.element_stack = []
    self.trksegs = []

  def startElement(self, name, attrs):
    self.element_stack.append(name)
    if name == "trkseg":
      self.trkseg = []
    elif name == "trkpt":
      lat = float(attrs["lat"])
      lon = float(attrs["lon"])
      self.trkpt = entry()
      self.trkpt.lat = lat
      self.trkpt.lon = lon
    elif name == "ele" and "trkpt" not in self.element_stack:
      print "Found an elevation outside of a trkpt. Help!"
    elif name == "time" and "trkpt" not in self.element_stack:
      print "Found a time outside of a trkpt. Help!"

  def endElement(self, name):
    popped = self.element_stack.pop()
    if popped != name:
      print "Found unexpected end element. Wanted %s, but got %s." % (
        popped, name)
      return
    if name == "trkpt":
      self.trkseg.append(self.trkpt)
    elif name == "trkseg":
      self.trksegs.append(self.trkseg)

  def characters(self, content):
    if self.element_stack[-1] == "ele":
      self.trkpt.ele = content
    elif self.element_stack[-1] == "time":
      self.trkpt.time = parse_time(content)

handler = gpx_parse()
parser = xml.sax.make_parser()
parser.setContentHandler(handler)
parser.parse(sys.stdin)
print handler.trksegs
