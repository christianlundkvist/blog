# Linear function defined by the matrix
# M = [[1, -1, 1], [6, 0, 0], [0, 1, 0]]
def M(u,v,w):
    return( (u - v + w, 6*u, v) )

R.<x,y,z> = PolynomialRing(QQ, 3)
F = x*(x+z)*(x+y) + y*(y+z)*(x+y) + z*(y+z)*(x+z) - 4*(y+z)*(x+z)*(x+y)

dFdx = F.derivative(x)
dFdy = F.derivative(y)
dFdz = F.derivative(z)

tangent = dFdx(-1,0,1)*(x - (-1)) + dFdy(-1,0,1)*(y - 0) + dFdz(-1,0,1)*(z - 1)
print('Tangent line: {0} = 0'.format(tangent))

# Groebner basis calculation shows that
# intersection of tangent line with
# curve F=0 has multiplicity 3:
I = Ideal([F, tangent])
B = I.groebner_basis()
print('Groebner basis has cubic term: {0}'.format(B))

S.<u,v,w> = PolynomialRing(QQ, 3)
print('G(u,v,w) = {0}'.format(F(u-v+w, 6*u, v)))

E2 = EllipticCurve(QQ, [-1, 47/2, 91/6, -455/12, -8281/216])
print('Curve E2: {0}'.format(E2))

E3 = EllipticCurve(QQ, [1,0,1,-234, 1352])
print('Curve E3: {0}'.format(E3))

phi = E3.isomorphism_to(E2)

Q0 = E3(-16,40,1)
Q1 = E3(23,79,1)

P0 = phi(Q0)
print('P0 = {0}'.format(P0))
P1 = phi(Q1)
print('P1 = {0}'.format(P1))

stop = False

for n in range(1, 11):
    if stop:
        break
    for m in range(6):
        if stop:
            break
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
            print('n = {0}'.format(n))
            print('m = {0}'.format(m))
            print('a = {0}'.format(a))
            print('b = {0}'.format(b))
            print('c = {0}'.format(c))
            print('a/(b+c) + b/(a+c) + c/(a+b) = {0}'.format(a/(b+c) + b/(a+c) + c/(a+b)) )
            stop = True

