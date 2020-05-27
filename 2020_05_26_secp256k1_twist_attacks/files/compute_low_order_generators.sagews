p = 115792089237316195423570985008687907853269984665640564039457584007908834671663

def compute_generator_and_order(curve):

    grp = curve.abelian_group()
        gen = grp.gens()[0]

    group_order = gen.order()

    return (gen, group_order)

def compute_subgroup_generator(group_generator, group_order, subgroup_order):

    other_factor = group_order // subgroup_order

    x = crt([1,0], [subgroup_order, other_factor])

    return (x*group_generator)

E1 = EllipticCurve(GF(p), [0,1])
(gen, order) = compute_generator_and_order(E1)
P11 = compute_subgroup_generator(gen, order, 20412485227)

print('P11 = {0}'.format(P11))

E2 = EllipticCurve(GF(p), [0,2])
(gen, order) = compute_generator_and_order(E2)
P21 = compute_subgroup_generator(gen, order, 3319)
P22 = compute_subgroup_generator(gen, order, 22639)

print('P21 = {0}'.format(P21))
print('P22 = {0}'.format(P22))

E3 = EllipticCurve(GF(p), [0,3])
(gen, order) = compute_generator_and_order(E3)
P31 = compute_subgroup_generator(gen, order, 109903)
P32 = compute_subgroup_generator(gen, order, 12977017)
P33 = compute_subgroup_generator(gen, order, 383229727)

print('P31 = {0}'.format(P31))
print('P32 = {0}'.format(P32))
print('P33 = {0}'.format(P33))

E4 = EllipticCurve(GF(p), [0,4])
(gen, order) = compute_generator_and_order(E4)
P41 = compute_subgroup_generator(gen, order, 18979)

print('P41 = {0}'.format(P41))

E6 = EllipticCurve(GF(p), [0,6])
(gen, order) = compute_generator_and_order(E6)
P61 = compute_subgroup_generator(gen, order, 10903)
P62 = compute_subgroup_generator(gen, order, 5290657)
P63 = compute_subgroup_generator(gen, order, 10833080827)
P64 = compute_subgroup_generator(gen, order, 22921299619447)

print('P61 = {0}'.format(P61))
print('P62 = {0}'.format(P62))
print('P63 = {0}'.format(P63))
print('P64 = {0}'.format(P64))

prod = 20412485227 * 3319 * 22639 *109903 * 12977017 * 383229727 * 18979 * 10903 * 5290657 * 10833080827 * 22921299619447

print(prod > 2**256)
