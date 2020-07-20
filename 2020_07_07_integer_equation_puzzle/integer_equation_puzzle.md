# Integer equation puzzle

*Christian Lundkvist, 2020-07-07*

## Introduction

I recently came across the following click-baity image floating around the internet:

![](https://github.com/christianlundkvist/blog/blob/master/2020_07_07_integer_equation_puzzle/files/original_puzzle.png?raw=true)

The image suggests a fun & simple math puzzle to spend a few minutes on. However, in this case in order to solve the problem you will need some heavy-duty mathematical machinery.

We will use the mathematical software package Sage for our calculations. The Sage code is in the following file:

[integer_equation.sagews](https://github.com/christianlundkvist/blog/blob/master/2020_07_07_integer_equation_puzzle/files/integer_equation.sagews)

If you don’t have Sage installed locally you can use it in a web browser at [CoCalc](https://cocalc.com) in order to run the calculations. Let’s dive in!

## Mathematical formulation and investigation

We first formulate the problem as follows: Find positive, non-zero integers x, y, z such that 

```
 x/(y+z) + y/(x+z) + z/(x+y) = 4.
```

In order to get started, first multiply both sides of the above equation by `(y+z)*(x+z)*(x+y)`. We then get a cubic equation

```
F(x,y,z) = x*(x+z)*(x+y) + y*(y+z)*(x+y) + z*(y+z)*(x+z) - 4*(y+z)*(x+z)*(x+y) = 0. (1)
```

This equation is homogeneous in `(x,y,z)` so we can view it as a cubic equation in the [projective plane](https://en.wikipedia.org/wiki/Projective_plane). Also we see that if we can find any rational point `(x,y,z)` fulfilling the above equation where all `x,y,z > 0` or `x,y,z < 0` we can get an integer solution by multiplying out by all denominators.

Thus we seek to understand the rational points on the curve defined by (1). We first test out and discover some simple rational points, like `(-1, 0, 1)` or `(-1, 1, 1)`. Furthermore we can also plot the points of (1) for `z=1`, and we can eyeball the graph and see that it looks smooth:

![](https://github.com/christianlundkvist/blog/blob/master/2020_07_07_integer_equation_puzzle/files/cubic_plot.jpg?raw=true)

Since a smooth cubic curve with coefficients in the rational numbers with an explicit rational point is an elliptic curve, it seems that the curve (1) is an elliptic curve.

## Transforming curve to stardard elliptic curve

We will next try to write our elliptic curve in a standard Weierstrass form, i.e. in the form

```
y^2 + a_1*x*y + a_3*y = x^3 + a_2*x^2 + a_4*x + a_6
```

where the coefficients `a_1, a_2, a_3, a_4, a_6` are rational. To do this we use the technique described in the following paper:

<https://trac.sagemath.org/raw-attachment/ticket/3416/cubic_to_weierstrass_documentation.pdf>

This involves first choosing a rational point on our cubic curve. In our case we select the point 

```
p = (p_x, p_y, p_z) = (-1, 0, 1). 
```

We then consider the tangent of the curve `F = 0` at the point `p`:

```
dF/dx(p)*(x - p_x) + dF/dy(p)*(y - p_y) + dF/dz(p)*(z - p_z) = 0.
```

Computing the above gives the line

```
6*x - y + 6*z = 0.
```

Following the procedure outlined in the paper, we can do a Groebner basis calculation using Sympy or Sage to verify that the tangent intersects the curve with multiplicity 3. We then choose another point on the tangent line that's not on the curve:

```
q = (1, 6, 0).
```

Choosing an arbitrary third point `(1, 0, 0)` that's linearly independent from the other two we can construct the coordinate change matrix below with `q` as the first column, `p` as the second column and the third point as our third column:

```
M = [[1, -1, 1], [6, 0, 0], [0, 1, 0]].
```

Using this matrix as our coordinate change we get a new equation:

```
G(u,v,w) = F(u - v + w, 6*u, v) = 0,
```

which computes to

```
91*u^3 - 141*u^2*w - 6*u*v*w + 6*v^2*w - 15*u*w^2 - 6*v*w^2 + w^3 = 0.
```

We can normalize this equation by dividing through by 91, and setting `w = -91/6` we obtain the desired Weierstrass form:

```
G(x,y,-91/6)/91 = x^3 + 47/2*x^2 + x*y - 455/12*x - y^2 - 91/6*y - 8281/216 = 0. (2)
```

Thus the Weierstrass coordinates for this elliptic curve are

```
[-1, 47/2, 91/6, -455/12, -8281/216].
```

We can type these coordinates into the following database of elliptic curves:

<https://www.lmfdb.org/EllipticCurve/>

This leads us to concluding that our elliptic curve is isomorphic to the curve defined here

<https://www.lmfdb.org/EllipticCurve/Q/910/a/4>

which has Weierstrass equation

```
y^2 + x*y + y = x^3 - 234*x + 1352. (3)
```

## Generating the group of rational points

The group of rational points (known as the [Mordell-Weil Group](https://en.wikipedia.org/wiki/Mordell%E2%80%93Weil_theorem)) on the elliptic curve defined by (3) has a known group structure:

```
H = ZZ x ZZ/(6).
```

The point `Q0 = (16, -40)` on the curve (3) corresponds to the point `(1,0)` in `H` (known as the Infinite Order Generator) and the point `Q1 = (23, 79)` on (3) corresponds to the point `(0,1)` in `H` (this point is called the Torsion Generator). Thus all the rational points on the curve (3) can be constructed as

```
n*Q0 + m*Q1
```

where `n` is a positive integer and `m` is an integer satisfying `0 <= m <= 5`.

We can use Sage to set up an isomorphism between curve (3) and our curve defined by equation (2):

```
E2 = EllipticCurve(QQ, [-1, 47/2, 91/6, -455/12, -8281/216])
E3 = EllipticCurve(QQ, [1,0,1,-234, 1352])

phi = E3.isomorphism_to(E2)
```

The above isomorphism `phi` will also be an isomorphism of the group structures of `E2` and `E3`. Thus the generators `Q0` and `Q1` of the group of rational points of `E3` will map to group generators of the rational points of `E2`:

```
P0 = phi(Q0)
P1 = phi(Q1)
```

It follows that all rational points of `E2` can be constructed as

```
P = n*P0 + m*P1 (4)
```

where `n` is an integer and `m` is an integer satisfying `0 <= m <= 5`.

Finally given any rational point `P` on `E2` we can map it to a rational point on our original curve (1) through the coordinate change matrix `M`. If the point `P` has coordinates `(P_x,P_y)` satisfying the equation (2), then 

```
M(P_x, P_y, -91/6)
```

will be a rational point on the original curve (1) and we can check if that point has coordinates that are all positive or all negative.

## Solution to the original puzzle

To put it all together we set up a double loop iterating through the integers `n` and `m` of (4) which will iterate through all the rational points of the curve `E2` which is then mapped via `M` to points on the curve (1).

Once we’ve found a rational point with all positive or all negative coordinates for the curve (1) then we can create an integer solution `(a,b,c)` by multiplying with the denominators and then dividing by the greatest common divisor:

```
for n in range(1, 11):
   for m in range(6):
       P = n*P0 + m*P1
        (Mx, My, Mz) = M(P.xy()[0], P.xy()[1], -Rational(91)/6)
        if (Mx>0 and My>0 and Mz>0) or (Mx<0 and My<0 and Mz<0):
            Mxd = Mx.denominator()
            Myd = My.denominator()
            Mzd = Mz.denominator()
            dd = Mxd*Myd*Mzd
            gg = gcd( gcd(Mx*dd, My*dd), Mz*dd)
            a = abs(Mx)*dd/gg
            b = abs(My)*dd/gg
            c = abs(Mz)*dd/gg
```

It turns out we get a match for `n = 9` and `m = 0`. The solution is as follows:

```
a = 154476802108746166441951315019919837485664325669565431700026634898253202035277999
b = 4373612677928697257861252602371390152816537558161613618621437993378423467772036
c = 36875131794129999827197811565225474825492979968971970996283137471637224634055579

a/(b+c) + b/(a+c) + c/(a+b) = 4
```

We've seen how to use the heavy machinery of elliptic curves in order to solve this puzzle. Not exactly the kind of solution you’d expect to find with some relaxed trial and error!
