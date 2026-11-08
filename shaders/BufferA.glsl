// Silk Waves (Shadertoy port), Buffer A. MIT License; the notice and credits are in the Common tab.
// The simulation. iChannel0 = Buffer A (itself).
// Rows 0-18 the 19 x 19 cloth's positions, 19-37 velocities and the wave clock, 38-56 the surface's control points
// now (the edge's clock in w), 57-75 a frame ago (the 60 Hz steps between in w), 76 the mood; rows 77-172 the 2,048
// flakes (place and age, velocity and ageing rate, orientation), one texel each per 64 x 32 block.

const uvec4 kWarm[181] = uvec4[181](
    uvec4(2906191770u,2228755344u,2449172255u,2161822228u), uvec4(2301935314u,3306521363u,2607879810u,1171993695u),
    uvec4(1923972644u,2259061680u,2435382735u,1536345199u), uvec4(1856515414u,1658852928u,2284369144u,1876716180u),
    uvec4(2275796104u,1944040486u,2741285927u,1121557426u), uvec4(2791754706u,2162400616u,2246300514u,1574552614u),
    uvec4(2586139404u,1654797278u,2040898205u,1957731016u), uvec4(2330006078u,2391703991u,2074159572u,2773959953u),
    uvec4(2342873457u,1427895360u,2287974662u,2748971992u), uvec4(2346750117u,2149581824u,2691505977u,1432249741u),
    uvec4(2394052333u,2296404984u,2049996425u,2971319362u), uvec4(2339073582u,1189078083u,2242473416u,1970003248u),
    uvec4(2502401369u,1733409459u,2389032206u,2049510576u), uvec4(2640512154u,1366094569u,2221114433u,2288741690u),
    uvec4(2342308830u,2044480215u,2791508868u,2178691550u), uvec4(2548079387u,1322674915u,2514533039u,2901472354u),
    uvec4(2094881387u,2052967612u,1972945416u,3267937070u), uvec4(1570466221u,2166760562u,1608454478u,1865104927u),
    uvec4(1424064758u,2308217864u,2380101797u,2149581824u), uvec4(2649691896u,1931758791u,2234625661u,1940024401u),
    uvec4(2267987483u,2149196743u,2431305154u,2649349417u), uvec4(2376674657u,618468668u,2351090956u,2018661532u),
    uvec4(2422457506u,2056811226u,2653121596u,2274827627u), uvec4(2464357336u,1394297885u,2485089146u,2334590023u),
    uvec4(2233801506u,2963254396u,2451237555u,2691198481u), uvec4(2334241360u,1062794535u,2161824255u,3038819579u),
    uvec4(2006493591u,1943862727u,1360609619u,1829891152u), uvec4(1159741705u,1298023710u,1134299280u,2888943203u),
    uvec4(2279225509u,2149581824u,1785237159u,1516490065u), uvec4(1869110863u,2808924806u,1965563352u,3151740007u),
    uvec4(2011219345u,2597203065u,1709376791u,2615610917u), uvec4(1524704458u,1662151731u,1659112535u,2728087420u),
    uvec4(1725850624u,1003805702u,1541542797u,2384683846u), uvec4(1936087869u,1767877649u,1944416993u,2891441547u),
    uvec4(1709099644u,2820635557u,1629784592u,3563140188u), uvec4(1537167797u,1881357279u,1633599822u,1633936477u),
    uvec4(1625600241u,2195307012u,1252282520u,2955418643u), uvec4(2044612685u,1138129797u,2098718885u,2149581824u),
    uvec4(1419994845u,1688243369u,1046826612u,2133080917u), uvec4(1486882319u,1524712114u,1197835697u,2401238010u),
    uvec4(1080419670u,3714312788u,925160693u,2828391280u), uvec4(933598349u,2283295089u,1214202921u,2170825384u),
    uvec4(1067787220u,1784734524u,1273459566u,2758048812u), uvec4(958501641u,2372488620u,1445302945u,2795832121u),
    uvec4(879090242u,2741044007u,1206278632u,3161040334u), uvec4(1315512700u,2115943460u,1911109951u,2773619744u),
    uvec4(2238245077u,3160521542u,2677967045u,2644478586u), uvec4(1947682981u,2149581824u,1319046988u,1768543400u),
    uvec4(1138970359u,2133449744u,1625816729u,2371892228u), uvec4(916653615u,2127977501u,1223013838u,2958891822u),
    uvec4(870706537u,2976126021u,958702855u,2686731098u), uvec4(1054856350u,2485964124u,950299711u,1725906210u),
    uvec4(1260940259u,1696168832u,1088279422u,2435021631u), uvec4(1218906910u,1410259841u,1289763511u,1712860496u),
    uvec4(1336314459u,1499182192u,1529278964u,2102315943u), uvec4(2238067117u,980822854u,2082873648u,3211330865u),
    uvec4(2707292417u,1362031831u,1914212517u,2149581824u), uvec4(1314490248u,1617378707u,1423830826u,1369768956u),
    uvec4(1218236095u,1504119864u,1835095652u,942185744u), uvec4(1495401992u,1994879902u,1486818712u,3085149381u),
    uvec4(1314710847u,2040939006u,1822559443u,1758809136u), uvec4(1524475015u,1708955015u,1394564130u,2149960336u),
    uvec4(1746756528u,1544813516u,1373553501u,1746738048u), uvec4(1503398631u,1156291796u,1642160795u,2079445524u),
    uvec4(1554016798u,2379551659u,2229113315u,2279883911u), uvec4(1407070553u,2771680274u,1574721851u,1517147154u),
    uvec4(2019248293u,2149581824u,2308253610u,1264196492u), uvec4(1989551926u,703425145u,2149111529u,2741065046u),
    uvec4(2228979311u,2925874627u,2119869985u,1852294165u), uvec4(2052787630u,2221814538u,1964668234u,2896757664u),
    uvec4(2207700196u,1721785640u,2279382146u,1922899487u), uvec4(2262529056u,2359049466u,2526694321u,1075544955u),
    uvec4(1977228122u,1659402918u,2169780989u,1274506219u), uvec4(2061005458u,2087412444u,1758886450u,841661179u),
    uvec4(1930717642u,2129128487u,1796573528u,2314040406u), uvec4(1578316014u,2095057514u,2199820453u,2149581824u),
    uvec4(2635593527u,1805808709u,2492884699u,2284578052u), uvec4(2463938166u,1814033755u,3008996882u,3304428265u),
    uvec4(2471855559u,3529077891u,2589168983u,1029126883u), uvec4(2593355010u,2736839856u,2568256664u,1297960357u),
    uvec4(2883206208u,2489091408u,2480337860u,2523224634u), uvec4(3008834419u,1154800138u,2572770052u,2543990106u),
    uvec4(2937594533u,1054962538u,2425539147u,2381929722u), uvec4(2543047159u,2170819403u,2320374159u,2591409250u),
    uvec4(2706831674u,1868544704u,2576574679u,2018362763u), uvec4(2351001765u,2149581824u,2438489817u,1517112120u),
    uvec4(2191150712u,2359645432u,1994081820u,2241469146u), uvec4(2408938948u,1524306932u,2383863133u,1691214502u),
    uvec4(2409139437u,2717551517u,2388061315u,2673933018u), uvec4(2707096612u,1134185315u,2824645580u,2765556791u),
    uvec4(2732145515u,2212920722u,2887588605u,2009877706u), uvec4(2782153394u,2602101954u,2631502414u,2190642521u),
    uvec4(2866063845u,2917383511u,2647818634u,3181325437u), uvec4(2639040807u,1700875385u,2811275462u,937689736u),
    uvec4(2912540840u,2438767159u,2380454053u,2149581824u), uvec4(1943279235u,1452747737u,1754598970u,2564751734u),
    uvec4(1834200516u,1537186853u,2358510965u,2846090158u), uvec4(2450681084u,2733390585u,2417124507u,1721756510u),
    uvec4(2211580981u,1516053557u,2241260500u,1968669691u), uvec4(2434270074u,2087044379u,2509495040u,1945590233u),
    uvec4(2568035009u,1838736468u,2488840777u,2043408565u), uvec4(2379340281u,698391931u,2241229203u,697195225u),
    uvec4(2060572971u,904033467u,2362683585u,2559937442u), uvec4(2295496803u,3428518699u,2015510616u,1641242954u),
    uvec4(2271369381u,2149581824u,1556926086u,2182437245u), uvec4(1489741354u,2955369148u,1385121220u,1645902799u),
    uvec4(1389196635u,1923816461u,1623934207u,2172901982u), uvec4(1464736915u,2400898366u,1267674170u,2423338162u),
    uvec4(1322683358u,2502816640u,1591178102u,1847524414u), uvec4(1444647701u,1605133545u,1670763189u,3018134049u),
    uvec4(1776013896u,1779824067u,1582561766u,2270565151u), uvec4(1590978954u,1291116070u,1448714535u,1666183998u),
    uvec4(1255424198u,2107529775u,1523493001u,2065315382u), uvec4(1922682921u,2299300886u,2090870949u,2149581824u),
    uvec4(1543808747u,2761759416u,1325825690u,1978041495u), uvec4(982228544u,2253941443u,1221369290u,2433890700u),
    uvec4(1426908548u,732358047u,1297059083u,2929284248u), uvec4(1246743735u,1319111393u,1297087558u,2074062415u),
    uvec4(1305762791u,2049168221u,1280744314u,1477792484u), uvec4(1293384466u,2304818416u,1398487736u,1488257793u),
    uvec4(1066955337u,2467877964u,907512299u,921812172u), uvec4(823468412u,800722499u,1259845933u,1213807369u),
    uvec4(923857076u,1466586014u,1783722110u,1044890713u), uvec4(1943861413u,2149581824u,1644824400u,2254195191u),
    uvec4(1841999591u,1299272577u,1615851150u,2350904269u), uvec4(1674470938u,2971562901u,1804455354u,2786728925u),
    uvec4(1636861260u,1528663375u,1838185720u,1906295419u), uvec4(1695777949u,1759732849u,1276376118u,1994142856u),
    uvec4(1595145156u,1504306074u,1242788723u,1667908482u), uvec4(1242919687u,867306433u,1159203503u,882199704u),
    uvec4(1423565384u,1986659448u,991607277u,3566730400u), uvec4(1071319431u,2510210465u,831914285u,2556560499u),
    uvec4(1263780056u,1316654226u,1914294437u,2149581824u), uvec4(2299514726u,3206812835u,1897015088u,2480685786u),
    uvec4(1851135668u,2770176947u,2219855454u,895288596u), uvec4(2412942843u,1507945480u,1679289785u,2401434933u),
    uvec4(1901671764u,1487160268u,1771652322u,2254986195u), uvec4(1604127888u,1745707956u,2077959203u,1844070170u),
    uvec4(1495096267u,1679133489u,1943616368u,2405209429u), uvec4(1855808243u,2669497097u,1637571228u,2225812257u),
    uvec4(1511631406u,1490891428u,1662886354u,2275646140u), uvec4(1327112540u,2011820657u,1641986304u,2740237206u),
    uvec4(2023209125u,2149581824u,2342086563u,2447586335u), uvec4(2270957338u,2695312273u,2702915294u,2003197037u),
    uvec4(2652468823u,2866352982u,2438786564u,1541041473u), uvec4(2187423128u,2598535937u,2342620484u,2112083191u),
    uvec4(2355201236u,1830255557u,2153823350u,1722310048u), uvec4(2283969544u,1384893734u,2275333033u,2836562706u),
    uvec4(2321552199u,1771498664u,2330047218u,1957786802u), uvec4(2711435906u,3185159544u,2337843773u,1654715395u),
    uvec4(2190836189u,2057840103u,2220474732u,2194345435u), uvec4(2279559472u,2229272459u,2207735973u,2149581824u),
    uvec4(2552282919u,2586618952u,2757574361u,2874940561u), uvec4(3193888387u,2762945643u,3378157073u,1876611971u),
    uvec4(3084996031u,2745707183u,2896270689u,1691050914u), uvec4(2691007736u,2359313393u,2632350868u,2430196694u),
    uvec4(2602910766u,1957004410u,3169149919u,1852203993u), uvec4(2510682981u,2124590222u,2858640156u,1742211813u),
    uvec4(2833826474u,2308537646u,2846044736u,2114535896u), uvec4(3046720069u,1205208538u,2866041308u,2505671585u),
    uvec4(2782310765u,2631256831u,2752827686u,1927207986u), uvec4(2354634917u,2149581824u,2895875820u,1864039469u),
    uvec4(3009425010u,1134613494u,2850020893u,2648867840u), uvec4(3294549418u,3013610534u,2942557523u,1490643914u),
    uvec4(2942686444u,1696254933u,3051693190u,2066510458u), uvec4(2946999336u,2057913253u,2733089727u,1775938422u),
    uvec4(2989114197u,1015583912u,2724825849u,1483233903u), uvec4(2821141142u,2803028989u,3265555008u,2908088996u),
    uvec4(3915409935u,1964608417u,3809991146u,1273537501u), uvec4(3562078621u,1813825933u,3537389851u,1814168543u),
    uvec4(3117744351u,2670010914u,2375796901u,2149581824u), uvec4(3327913602u,1507738222u,3114245651u,3265410152u),
    uvec4(3072069048u,1611717784u,3055058259u,1130242988u), uvec4(2694634744u,2056827999u,2841666722u,1541731588u),
    uvec4(2850128950u,2292259949u,3047269344u,2984903657u), uvec4(2820494189u,2690784020u,3382833952u,2819224303u),
    uvec4(3038870203u,1974073998u,3030626905u,916239279u), uvec4(3622029840u,1566588496u,3781091750u,2469229412u),
    uvec4(3725894052u,1323826082u,3373457696u,2838097143u), uvec4(3642050760u,2061998876u,2887465071u,2334432414u),
    uvec4(2266962085u,2149581824u,0u,0u)
);

// A node of the warm start: a sheet from our own run of this model, packed 11:11:10 bits.
const vec3 kWarmLow = vec3(-0.5, -0.8, -0.8), kWarmSpan = vec3(6.2, 2.2, 1.8);
const float kWarmSpeed = 24.0;
void warm_node(int index, out vec3 position, out vec3 velocity) {
    uvec4 pair = kWarm[index >> 1];
    uvec2 word = (index & 1) != 0 ? pair.zw : pair.xy;
    vec3 scale = 1.0 / vec3(2047.0, 2047.0, 1023.0);
    position = vec3(uvec3(word.x & 2047u, (word.x >> 11) & 2047u, word.x >> 22)) * scale * kWarmSpan + kWarmLow;
    velocity = (vec3(uvec3(word.y & 2047u, (word.y >> 11) & 2047u, word.y >> 22)) * scale - 0.5) * kWarmSpeed;
}

vec3 cloth_node(int row, int column) { return texelFetch(iChannel0, ivec2(column, row), 0).xyz; }

// One frame of a node's simulation: springs to the neighbours on each side and, ten times stiffer, two away; a random
// push; damping; the free edge pulled outward; the driven edge on its Lissajous curve.
void step_node(int row, int column, out vec3 node, out vec3 velocity, out float t, out float lag) {
    vec4 held = texelFetch(iChannel0, ivec2(column, 19 + row), 0);
    float steps = frame_steps(iTimeDelta);
    node = cloth_node(row, column);
    velocity = held.xyz;
    t = held.w;
    lag = texelFetch(iChannel0, ivec2(0, 38), 0).w;
    vec3 force = vec3(0.0);
    for (int s = 0; s < 8; ++s) {
        ivec2 n = s == 0 ? ivec2(0, -1) : s == 1 ? ivec2(0, 1) : s == 2 ? ivec2(-1, 0) : s == 3 ? ivec2(1, 0)
                : s == 4 ? ivec2(0, -2) : s == 5 ? ivec2(0, 2) : s == 6 ? ivec2(-2, 0) : ivec2(2, 0);
        ivec2 other = ivec2(row, column) + n;
        if (all(greaterThanEqual(other, ivec2(0))) && all(lessThanEqual(other, ivec2(18)))) {
            vec3 d = cloth_node(other.x, other.y) - node;
            float length_ = max(length(d), 1e-6);
            force += d * ((length_ - kRest * (s < 4 ? 1.0 : 2.0)) * kTension * (s < 4 ? 1.0 : 10.0) / length_);
        }
    }
    vec3 push = hash4(vec2(float(row * 19 + column + 32768), float(iFrame))).xyz * 2.0 - 1.0;
    velocity += steps * force + sqrt(steps) * kPush * push;
    node += velocity * (kStep * steps);
    velocity -= velocity * (kDamping * steps);
    t += kStep * steps;
    if (t > kWrap)
        t = 0.0;
    lag += (t - lag) * (1.0 - pow(0.9, steps));
    if (column == 0)
        velocity.x += kPull * steps;
    if (column == 18) {
        node = driven_edge(row, lag);
        velocity = vec3(0.0);
    }
}

// A node after this frame's step, or on a new start from the warm sheet (`past`: a step before it).
void node_after(int row, int column, bool fresh, bool past, out vec3 node, out vec3 velocity, out float t, out float lag) {
    if (fresh) {
        warm_node(row * 19 + column, node, velocity);
        t = kStartClock;
        lag = kStartLag;
        if (past) {
            node = column == 18 ? driven_edge(row, kStartLag - kStep) : node - velocity * kStep;
            t -= kStep;
        }
    } else {
        step_node(row, column, node, velocity, t, lag);
    }
}

// The emitter: births come from vertices of the ribbon's mesh, random ones or, one in sixteen while a streak runs,
// the streak's (one per 300 steps of the wave clock, walking along the ribbon).
uvec2 birth_vertex(vec4 r, float choice, bool fresh) {
    uvec2 vertex = uvec2(r.xy * 127.0);
    float t = kStartClock;
    if (!fresh) {
        t = texelFetch(iChannel0, ivec2(0, 19), 0).w + kStep * frame_steps(iTimeDelta);
        if (t > kWrap)
            t = 0.0;
    }
    float frame_ = floor(t / kStep);
    float slot = floor(frame_ / 300.0), since = frame_ - slot * 300.0;
    vec4 streak = hash4(vec2(slot, 4242.0));
    float start = floor(streak.z * 127.0), step = floor((since - floor(streak.x * 34.0)) * 0.5);
    float length_ = min(floor(80.0 * (2.0 * streak.w - 1.0)) + 100.0, 128.0 - start);
    if (step >= 0.0 && step < length_ && choice < 0.06)
        vertex = uvec2(uint(start + step), uint(floor(streak.y * 127.0)));
    return vertex;
}

// A new flake at a vertex (surface point p now, `before` a step earlier), launched in a 52 degree cone about the way
// the vertex moves (backwards one time in six), flattened onto the screen plane; `settled` places a first-frame
// flake partway through its life.
void spawn(vec3 p, vec3 before, float steps, vec4 a, vec4 b, vec4 c, bool settled, out vec4 place, out vec4 motion,
           out vec4 orientation) {
    vec3 drift = (p - before) / (max(steps, 1e-6) * kTick);
    float pace = length(drift);
    float rate = max(0.001, 0.0029 * (1.0 + 0.5 * (2.0 * b.z - 1.0)));
    float r1 = sqrt(1.0 - c.x), r2 = sqrt(c.x);
    orientation = vec4(r1 * sin(2.0 * kPi * c.y), r1 * cos(2.0 * kPi * c.y), r2 * sin(2.0 * kPi * c.z), r2 * cos(2.0 * kPi * c.z));
    if (steps < 1e-3 || pace < 1e-4) {
        place = vec4(p + vec3(0.0, 0.0, 2.0), 1.0);
        motion = vec4(0.0, 0.0, 0.0, rate);
        return;
    }
    vec3 axis = drift / pace * (b.x < 0.17 ? -1.0 : 1.0);
    vec3 s1 = vec3(0.0, axis.z, -axis.y), s2 = vec3(-axis.z, 0.0, axis.x), s3 = vec3(axis.y, -axis.x, 0.0);
    float l1 = dot(s1, s1), l2 = dot(s2, s2), l3 = dot(s3, s3);
    vec3 side = normalize(l1 >= l2 && l1 >= l3 ? s1 : l2 >= l3 ? s2 : s3), third = cross(axis, side);
    float tilt = a.z * radians(52.0), around = a.w * 2.0 * kPi;
    vec3 direction = axis * cos(tilt) + (side * cos(around) + third * sin(around)) * sin(tilt);
    float speed = max(0.15, sqrt(pace * 0.19 * (1.0 + 0.28 * (2.0 * b.y - 1.0))));
    vec3 velocity = vec3(direction.xy * speed, 0.0);
    float age = settled ? b.w : 0.0;
    place = vec4(p + vec3(0.0, 0.0, 2.0) + velocity * (kTick * age / rate), age);
    motion = vec4(velocity, rate);
}

// A flake's frame: drift (with a small push of its slot's own), jostle, age and spin. True when it is reborn.
bool flake_moves(float id, inout vec4 place, inout vec4 motion, inout vec4 orientation) {
    float steps = frame_steps(iTimeDelta);
    vec3 kick = hash4(vec2(id, float(iFrame))).xyz * 2.0 - 1.0;
    vec4 r = hash4(vec2(id + 40960.0, 7.0));
    vec2 radius = sqrt(-2.0 * log(max(r.xz, 1e-7)));
    vec3 drift = vec3(radius.x * cos(2.0 * kPi * r.y), radius.x * sin(2.0 * kPi * r.y), radius.y * cos(2.0 * kPi * r.w)) * 0.00052;
    motion.xyz += kTick * (sqrt(steps) * kKick * kick + steps * (vec3(0.0, kGravity, 0.0) - kDrag * motion.xyz)) + steps * drift;
    place.xyz += steps * kTick * motion.xyz;
    place.w += steps * motion.w;
    vec3 spin = vec3(sin(0.74 * kPi * place.w), cos(0.34 * kPi * place.w), cos(0.62 * kPi * place.w));
    float angle = length(spin) * kSpin * steps;
    orientation = normalize(quaternion_product(vec4(normalize(spin) * sin(0.5 * angle), cos(0.5 * angle)), orientation));
    return place.w > 0.99999 || any(lessThan(place.xyz, kBoundsLow)) || any(greaterThan(place.xyz, kBoundsHigh));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    ivec2 texel = ivec2(fragCoord);
    fragColor = vec4(0.0);
    if (texel.x >= 64 || texel.y >= kFlakeRow + 96)
        return;
    bool fresh = iFrame == 0 || texelFetch(iChannel0, ivec2(0, 0), 0).w == 0.0, flake = texel.y >= kFlakeRow;
    int block = flake ? (texel.y - kFlakeRow) >> 5 : texel.y / 19;
    if (texel.y == kMoodRow) {
        if (texel.x < 6)
            fragColor = mood_texel(mood(iDate), texel.x, iDate);
        return;
    }
    if (!flake && texel.x >= 19)
        return;
    if (!flake && block == 3 && !fresh) {
        fragColor = vec4(texelFetch(iChannel0, ivec2(texel.x, texel.y - 19), 0).xyz, frame_steps(iTimeDelta));
        return;
    }
    ivec2 slot = ivec2(texel.x, (texel.y - kFlakeRow) & 31);
    float id = float(slot.y * 64 + slot.x);
    vec4 place = vec4(0.0), motion = vec4(0.0), orientation = vec4(0.0), a = vec4(0.0), b = vec4(0.0), c = vec4(0.0);
    bool settled = false, born = false;
    vec2 uv = vec2(0.0);
    ivec2 origin = ivec2(texel.x, texel.y - block * 19);
    vec4 bu = vec4(1.0, 0.0, 0.0, 0.0), bv = bu;
    int count = 1;
    bool control = block >= 2;
    if (flake) {
        place = texelFetch(iChannel0, slot + ivec2(0, kFlakeRow), 0);
        motion = texelFetch(iChannel0, slot + ivec2(0, kFlakeRow + 32), 0);
        orientation = texelFetch(iChannel0, slot + ivec2(0, kFlakeRow + 64), 0);
        if (fresh)
            place = motion = orientation = vec4(0.0);
        settled = motion.w == 0.0;
        born = settled;
        if (!settled)
            born = flake_moves(id, place, motion, orientation);
        count = 0;
        if (born) {
            a = hash4(vec2(id + 8192.0, float(iFrame)));
            b = hash4(vec2(id + 16384.0, float(iFrame)));
            c = hash4(vec2(id + 24576.0, float(iFrame)));
            uvec2 vertex = birth_vertex(a, c.w, fresh);
            uv = vec2(vertex >> 3u) + vec2(vertex & 7u) * (16.0 / 127.0);
            origin = min(ivec2(uv), 15);
            bu = bspline(uv.x - float(origin.x));
            bv = bspline(uv.y - float(origin.y));
            count = fresh ? 32 : 16;
            control = true;
        }
    }
    // One loop over nodes: a cloth texel's own node, or the sixteen around a newborn flake's vertex (stepped here,
    // since this buffer still holds last frame's control points; on a new start, now and a step before).
    Mood m = mood(iDate);
    vec3 node = vec3(0.0), velocity = vec3(0.0), now = vec3(0.0), before = vec3(0.0), row_ = vec3(0.0);
    float t = 0.0, lag = 0.0;
    for (int i = 0; i < count; ++i) {
        bool past = flake ? i >= 16 : block == 3;
        int across = flake ? (i >> 2) & 3 : 0, along = flake ? i & 3 : 0;
        node_after(origin.y + across, origin.x + along, fresh, past, node, velocity, t, lag);
        if (control)
            row_ += bu[along] * control_point(node, t, m);
        if (along == 3 || !flake) {
            if (past)
                before += bv[across] * row_;
            else
                now += bv[across] * row_;
            row_ = vec3(0.0);
        }
    }
    if (!flake) {
        fragColor = block == 0 ? vec4(node, 1.0) : block == 1 ? vec4(velocity, t) : block == 2 ? vec4(now, lag) : vec4(before, 1.0);
        return;
    }
    if (born) {
        vec3 along_, across_;
        if (!fresh)
            surface(iChannel0, uv, 38, before, along_, across_);
        spawn(now, before, fresh ? 1.0 : frame_steps(iTimeDelta), a, b, c, settled, place, motion, orientation);
    }
    fragColor = block == 0 ? place : block == 1 ? motion : orientation;
}
