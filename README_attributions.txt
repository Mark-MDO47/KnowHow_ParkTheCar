roundCornersCube.scad is from http://www.thingiverse.com/thing:8812
Round corners for Openscad - Library
by WarrantyVoider, published May 26, 2011

Summary

Making a cube in OpenScad takes just one line of code. Making it nicer (with rounded corners) takes... 40 lines of code!
But hey, the good thing about OpenScad is that once someone makes a library, everything becomes trivial.
So now, making tidy iPhonesque shapes requires just a line of code:
roundCornersCube(10,5,2,1);

Instructions

You have several options to use this library:
a) Open the .scad file, copy its content and paste it in your script
b) Include the file in your script with any of these commands:
include<"roundCornersCube.stl">
use<"roundCornersCube">
For this option, the library file should be in the same folder as your script.
c) Download the file and copy it in /usr/local/share/openscad/libraries (at least for Ubuntu) Then add it using:
use

Calling it:
roundCornersCube(x,y,z,r) Where:

x = Xdir width
y = Ydir width
z = Height of the cube
r = Rounding radious
Example: roundCornerCube(10,10,2,1);
*Some times it's needed to use F6 to see good results!