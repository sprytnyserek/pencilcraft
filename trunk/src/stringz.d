module stringz;

import std.string;
import std.math;
import std.format;

void ftostr(float f,char* str) {
char[] str2;
str2 = std.string.format("%.4f",f);
for (uint i = 0; i <= str2.length; i++) {
	if (i < str2.length) str[i] = str2[i]; else str[i] = '\0';
	}
delete str2[];
};

void uitostr(uint i,char* str) {
char[] str2;
str2 = std.string.format("%d",i);
for (uint j = 0; j <= str2.length; j++) {
	if (j < str2.length) str[j] = str2[j]; else str[j] = '\0';
	}
delete str2[];
};
