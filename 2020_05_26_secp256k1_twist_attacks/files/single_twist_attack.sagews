# Note that these encrypt and decrypt functions are
# dummy stub functions to illustrate the main
# points.

def encrypt(symmkey, message):
    return symmkey

def key_does_decrypt(symmkey, cipherText):
    return (symmkey == cipherText)

b = 0x23fbd850a237fe4d283e4ca287aa6f8339f2f6dd134db1f6bb4861f6965749eb

p = 115792089237316195423570985008687907853269984665640564039457584007908834671663
E = EllipticCurve(GF(p), [0,2])
Grp = E.abelian_group()
g = Grp.gens()[0]
numElements = g.order()
print( "{0} = {1}".format(numElements, factor(numElements)) )

n1 = 3
n2 = 13*13
n3 = 3319
n4 = 22639
n5 = 1013176677300131846900870239606035638738100997248092069256697437031

x = crt([0,0,1,0,0], [n1,n2,n3,n4,n5])
print(x)
P = x*g
print(P)
print('order of P = {0}'.format(P.order()))

Q = b * P

cipherText = encrypt(Q, "Hello")

y = 0
for i in range(1, 3319):
  if key_does_decrypt(i*P, cipherText):
      y = i

print('b mod 3319 = {0}'.format(y))
