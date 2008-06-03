module matrices;

private import std.string;
private import std.stdio;
private import std.c.stdlib;

private import sdlexception;
private import shape;

class Matrix {
	protected:
	float[][] array;
	uint r,c;
	
	public:
	this(uint m,uint n) {
	synchronized {
		array.length = m;
		for (uint i = 0; i < m; i++) array[i].length = n;
		for (uint i = 0; i < m; i++) for (uint j = 0; j < n; j++) array[i][j] = 0.0;
		this.r = m;
		this.c = n;
		}
	};
	
	this(float[][] array) {
	uint m, n;
	synchronized {
		this.array.length = array.length;
		if (this.array.length == 0) this.r = this.c = 0; else {
			m = this.array.length;
			for (uint i = 0; i < m; i++) {
				if (i == 0) n = array[i].length; else {
					if (array[i].length != n) {
						this.array.length = this.r = this.c = 0;
						break;
						}
					}
				this.array[i][] = array[i][];
				}
			this.r = m;
			this.c = n;
			}
		}
	};
	
	/+synchronized this(Matrix matrix) {
	this.r = matrix.r;
	this.c = matrix.c;
	this.array.length = this.r;
	for (uint i = 0; i < this.r; i++) this.array[i][] = matrix.array[i][];
	};+/
	
	~this() {
	/+uint i;
	for (i = 0; i < this.r; i++) this.array[i].length = 0;
	this.array.length = 0;+/
	//delete this.array[][];
	};
	
	synchronized Matrix opAdd(Matrix b) {
	if ((this.r != b.r) || (this.c != b.c)) throw new SDLException();
	Matrix c = new Matrix(this.r,this.c);
	for (uint i = 0; i < this.r; i++) for (uint j = 0; j < this.c; j++) c.array[i][j] = this.array[i][j] + b.array[i][j];
	return c;
	};
	
	synchronized Matrix opAddAssign(Matrix b) {
	if ((this.r != b.r) || (this.c != b.c)) throw new SDLException();
	for (uint i = 0; i < this.r; i++) for (uint j = 0; j < this.c; j++) this.array[i][j] += b.array[i][j];
	return this;
	};
	
	Matrix opMul(Matrix b) {
	if (this.c != b.r) throw new SDLException();
	Matrix c = new Matrix(this.r,b.c);
	for (uint i = 0; i < c.r; i++) for (uint j = 0; j < c.c; j++) for (uint k = 0; k < this.c; k++) c.array[i][j] += this.array[i][k] * b.array[k][j];
	return c;
	};

	synchronized float[] opMul(TVector4 v) {
	if ((this.r != 4) || (this.c != 4)) throw new SDLException();
	float[] w;
	w.length = 4;
	for (uint i = 0; i < 4; i++) {
		for (uint j = 0; j < 4; j++) {
			w[i] += this.array[i][j] * v[j];
			}
		}
	return w;
	};

	synchronized float[] opMul(TVector3 v) {
	if ((this.r != 3) || (this.c != 3)) throw new SDLException();
	float[] w;
	w.length = 3;
	for (uint i = 0; i < 3; i++) {
		for (uint j = 0; j < 3; j++) {
			w[i] += this.array[i][j] * v[j];
			}
		}
	return w;
	};

	synchronized float[] opMul(TVector2 v) {
	if ((this.r != 2) || (this.c != 2)) throw new SDLException();
	float[] w;
	w.length = 2;
	for (uint i = 0; i < 2; i++) {
		for (uint j = 0; j < 2; j++) {
			w[i] += this.array[i][j] * v[j];
			}
		}
	return w;
	};

	float opIndex(uint i,uint j) {
	if ((i >= this.r) || (j >= this.c)) throw new SDLException();
	return this.array[i][j];
	};

	synchronized float opIndexAssign(float value,uint i,uint j) {
	if ((i >= this.r) || (j >= this.c)) throw new SDLException();
	this.array[i][j] = value;
	return this.array[i][j];
	};

	void apMul(Matrix m) {
	if ((m is null) || (this.r != m.r) || (this.c != m.c)) return;
	uint i,j,k;
	float** c;
	//temp = cast(float*)calloc(this.r,float.sizeof);
	/+Matrix temp = new Matrix(this.r,this.c);
	for (i = 0; i < this.r; i++) for (j = 0; j < this.r; j++) {
		for (uint k = 0; k < this.r; k++) temp[i,j] = m.array[i][k] * this.array[k][j];
		}
	for (i = 0; i < this.r; i++) for (j = 0; j < this.r; j++) this.array[i][j] = temp[i,j];
	delete temp;+/
	/+for (i = 0; i < this.c; i++) {
		for (j = 0; j < this.r; j++) {
			temp[j] = this.array[j][i];
			}
		for (j = 0; j < this.r; j++) {
			this.array[j][i] = 0.0;
			for (k = 0; k < this.c; k++) {
				this.array[j][i] += m.array[i][k] * temp[k];
				}
			}
		}
	free(temp);+/
	c = cast(float**)calloc(this.r,(float*).sizeof);
	for (i = 0; i < this.r; i++) c[i] = cast(float*)calloc(this.c,float.sizeof);
	for (i = 0; i < this.r; i++) for (j = 0; j < this.c; j++) {
		c[i][j] = 0.0;
		for (k = 0; k < this.c; k++) c[i][j] += m.array[i][k] * this.array[k][j];
		}
	for (i = 0; i < this.r; i++) for (j = 0; j < this.c; j++) this.array[i][j] = c[i][j];
	for (i = 0; i < this.r; i++) free(c[i]);
	free(c);
	};
	
	/+
	void update(TVector4 v) {
	float[] w = this.opMul(v);
	for (uint i = 0; i < 4; i++) v[i] = w[i];
	};

	void update(TVector3 v) {
	float[] w = this.opMul(v);
	for (uint i = 0; i < 3; i++) v[i] = w[i];
	};

	void update(TVector2 v) {
	float[] w = this.opMul(v);
	for (uint i = 0; i < 2; i++) v[i] = w[i];
	};
	+/
	char[] toString() {
	char[] result;
	result.length = 0;
	for (uint i = 0; i < this.r; i++) {
		//if (i == 0) result ~= cast(char[])([218]);
		//if (i == 0) result ~= "┌";
		//if (i == this.r - 1) result ~= cast(char[])([192]);
		//if (i == this.r - 1) result ~= "└";
		//if ((i > 0) && (i < this.r - 1)) result ~= cast(char[])([179]);
		//if ((i > 0) && (i < this.r - 1)) result ~= "│";
		//result ~= " ";
		for (uint j = 0; j < this.c; j++) {
			result ~= std.string.toString(this.array[i][j]) ~ " ";
			}
		if (i == 0) {
			//result ~= cast(char[])([191]) ~ newline;
			//result ~= "┐" ~ newline;
			result ~= newline;
			}
		if (i == this.r - 1) {
			//result ~= cast(char[])([217]);
			//result ~= "┘";
			}
		if ((i > 0) && (i < this.r - 1)) {
			//result ~= cast(char[])([179]) ~ newline;
			//result ~= "│" ~ newline;
			result ~= newline;
			}
		}
	return result;
	};

	void show() {
	writefln(this.r," ",this.c);
	for (uint i = 0; i < this.r; i++) for (uint j = 0; j < this.c; j++) printf("%f",this.array[i][j]);
	};

	uint getRowSize() {
	return this.r;
	};

	uint getColumnSize() {
	return this.c;
	};
	
	};

class SqMatrix : Matrix {
	public:
	this(uint n) {
	super(n,n);
	};
	
	};

class Matrix4x4 {
	protected:
	
	
	public:
	
	
	};

void transform(Matrix m,TVector3 v) {
if (m is null) throw new SDLException();
uint r = m.getRowSize(), c = m.getColumnSize();
if ((r != 4) || (c != 4)) throw new SDLException();
float[4] w;
/+w.length = 4;+/
synchronized {
	w[0..3] = v[];
	w[3] = 1.0;
	for (uint i = 0; i < 3; i++) {
		v[i] = 0.0;
		for (uint j = 0; j < 4; j++) v[i] += m[i,j] * w[j];
		}
	} // synchronized
};
