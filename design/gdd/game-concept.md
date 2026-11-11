# Game Concept: Arknights – Operator Clash: Tactical Deployment

*Created: 2026-10-31*
*Status: Draft*

> **Quyết định 2026-11-10 (user): game đối kháng 2D dùng sprite**, thay cho hướng
> 2.5D / chibi 3D ghép khối cứng. Sim không đổi (vốn là mặt phẳng 2D số nguyên).
> Các mục bên dưới đã sửa theo quyết định này; art bible và ADR-0002 còn chờ sửa
> cho 2D (xem banner trong từng file).

> **Fan game, phi thương mại.** Arknights, các Operator và thế giới Terra thuộc
> Hypergryph / Yostar. Mọi asset (model, texture, UI, âm thanh, logo, font) là bản
> gốc tự làm hoặc placeholder; không sao chép tài sản có bản quyền. Kiểm tra quy
> định fan content của chủ IP trước khi phân phối.

---

## Elevator Pitch

> Game đối kháng 1v1 góc nhìn ngang, nơi bạn điều khiển các Operator Arknights
> chibi 2D (sprite): combo nhanh và mượt, nạp SP theo đúng kiểu của class (tự nạp, nạp khi
> đánh trúng, nạp khi chịu đòn), rồi kích hoạt kỹ năng có thời hạn để lật ngược
> trận đấu — chơi cùng máy hoặc qua LAN (Hamachi / Radmin) với bạn bè.

*Test 10 giây:* "Street Fighter với nhân vật Arknights, mỗi class nạp năng lượng
theo một kiểu khác nhau."

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Fighting game 1v1, **2D** (sprite, mặt phẳng chiến đấu ngang); anime arena fighter |
| **Platform** | PC (Windows), ứng dụng desktop cài đặt |
| **Target Audience** | Mid-core: fan Arknights và người thích game đối kháng dễ vào nhưng có chiều sâu (xem Target Player Profile) |
| **Player Count** | 1 người (vs AI), 2 người cùng máy, 2 người qua LAN / LAN ảo (Tier 1) |
| **Session Length** | 30–60 phút (trận best-of-3 khoảng 3–5 phút) |
| **Monetization** | Không có — fan game miễn phí, phi thương mại |
| **Estimated Scope** | Large (30+ tháng cho full vision, solo); MVP chơi được ~6,5 tháng (dự kiến) |
| **Comparable Titles** | Granblue Fantasy Versus, Dragon Ball FighterZ, Under Night In-Birth |

---

## Core Fantasy

Bạn điều khiển các Operator Arknights như những chiến binh thực thụ, không phải
quân cờ trên bản đồ tower defense. Ch'en lao vào chém liên hoàn và mỗi đòn trúng
làm SP dâng lên; Amiya giữ khoảng cách, để Arts tích tụ theo thời gian rồi giải
phóng; Mudrock đứng vững hứng đòn, biến từng cú bị đánh thành sức mạnh phản công.
Bạn cảm nhận được trọng lượng của từng đòn và cá tính của nhân vật qua **cách họ
chiến đấu** — và khoảnh khắc đỉnh cao là khi một kỹ năng hay một pha phản công
đúng lúc bùng nổ cùng lúc ở animation, âm thanh và hiệu ứng. *Pha phản công* ở đây
là thứ đã có trong Combat Slice, không cần cơ chế mới: phạt bằng combo đầy đủ một
Ultimate bị đỡ/trượt hoặc một Throw trượt, và ngắt trạng thái kỹ năng của đối thủ
bằng đòn trúng.

---

## Unique Hook

**Như Granblue Fantasy Versus, VÀ CÒN mỗi Operator nạp SP theo kiểu Arknights của
class mình, và kỹ năng là một *trạng thái có thời hạn* chứ không chỉ là một đòn.**

- **Auto** (vd. Caster): SP tự nạp theo tick — thưởng cho kiên nhẫn và giữ tầm.
- **Offensive** (vd. Guard): SP nạp khi đánh trúng — thưởng cho áp lực.
- **Defensive** (vd. Defender): SP nạp khi đỡ đòn / bị đánh — thưởng cho trụ vững.

Khi kỹ năng kích hoạt (vd. Surtr vào trạng thái lửa vài giây), cả hai người chơi
đổi chiến thuật: người dùng tận dụng cửa sổ, đối thủ né hoặc ép đánh để cắt nhịp.
Hook ảnh hưởng trực tiếp tới gameplay: nó thay đổi *khi nào* mỗi Operator muốn
đánh, lùi, hay đỡ.

*Phương án đã cân nhắc:* (1) counter-centric "Breakthrough" — hấp dẫn nhưng đòi
frame data cực chuẩn ngay từ đầu; (3) spectacle "Overload" — dễ vào nhưng dễ nông,
mâu thuẫn với mong muốn tránh sự đơn điệu. Người dùng chọn Tactical Deployment vì
nó kết hợp tình yêu với hệ thống chiến thuật Arknights và game đối kháng.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Challenge** (obstacle course, mastery) | 1 | Combo, nhịp SP, trạng thái kỹ năng, AI 3 cấp, đọc vị tài nguyên đối thủ |
| **Fantasy** (make-believe, role-playing) | 2 | Điều khiển Operator yêu thích, class và kiểu SP nhận ra ngay |
| **Sensation** (sensory pleasure) | 3 | Hit-stop, trail, tia va chạm màu class, rung màn hình (chỉ lớp thế giới), cut-in Ultimate |
| **Fellowship** (social connection) | 4 | Versus cùng máy, LAN với bạn bè (Tier 1) |
| **Expression** (self-expression, creativity) | 5 | Chọn class hợp lối chơi, tự tìm route combo |
| **Discovery** (exploration, secrets) | 6 | Operator Collection, học matchup |
| **Narrative** (drama, story arc) | N/A | Không có story mode trong mọi tier đã lên kế hoạch |
| **Submission** (relaxation, comfort zone) | N/A | Game thiên về thử thách |

### Key Dynamics (Emergent player behaviors)

- Người chơi theo dõi thanh SP của **đối thủ** và chơi an toàn khi đối thủ gần đầy.
- Người chơi Offensive-SP mạo hiểm tấn công để "đổi" rủi ro lấy SP; người chơi
  Defensive-SP cố tình block để nạp, tạo nhịp "trụ rồi bùng nổ".
- Khi kỹ năng đối thủ kích hoạt, người chơi tìm cách cắt nhịp hoặc chịu đựng hết
  thời gian — đây là lúc quyết định trận đấu.
- Người chơi thử từng Operator để tìm class hợp với mình, rồi luyện combo trong
  Training.

### Core Mechanics (Systems we build)

1. **Combat sim tất định 60 Hz** — Light/Heavy/Air/Special, tổ hợp hướng + nút,
   input buffer, cancel window, hitbox/hurtbox theo frame từ dữ liệu, hitstun,
   knockback, hit-stop.
2. **Phòng thủ** — **Sàn counterplay không bao giờ bị cắt:** Block, di chuyển, và
   ngắt trạng thái kỹ năng bằng đòn trúng (mỗi kỹ năng có ngưỡng số đòn riêng).
   **Throw** thắng Block, là công cụ chống chơi thủ. Perfect Guard và Dodge là phần
   thêm, là thứ cắt đầu tiên nếu Tier 0 trễ.
   **Vòng tam giác Throw (không bao giờ cắt, cùng sàn counterplay):**
   - *Throw thắng Block:* không đỡ được; tầm rất ngắn.
   - *Đòn đánh thắng Throw:* startup của Throw chậm hơn Light nhanh nhất và không có
     khung bất khả xâm phạm — bị đánh trúng trong startup là Throw bị hủy.
   - *Di chuyển thắng Throw:* lùi, nhảy hoặc ra khỏi tầm làm Throw trượt; Throw trượt
     có recovery dài, bị phạt bằng combo đầy đủ.
   - *Thoát Throw (throw tech):* bị túm thì bấm Throw trong một cửa sổ ngắn để thoát —
     không ai mất máu, hai bên đẩy ra về trạng thái trung lập.
   - *Không lặp Throw:* không ném được đối thủ đang hitstun, blockstun hoặc trên không;
     sau một Throw trúng, hai bên tách ra về trung lập (Throw không nối combo).
3. **Hệ thống SP theo kiểu + kỹ năng có thời hạn** — Auto / Offensive / Defensive;
   kỹ năng là trạng thái đếm bằng tick; luôn có cách để đối thủ chống trả.
4. **Ultimate** — đòn mạnh nhất kèm cinematic ngắn (Tier 0: 60 tick freeze +
   camera đẩy vào + cut-in; Tier 1: tối đa 150 tick = 2,5 giây). **Tài nguyên:**
   thanh Ultimate riêng, nạp chậm hơn SP và **từ cùng nguồn với kiểu SP** của
   Operator (Auto theo tick, Offensive khi đánh trúng, Defensive khi đỡ/chịu đòn),
   để bản sắc class vẫn giữ nguyên.
   **Ultimate dùng thô (không qua combo) tuân theo sàn counterplay, không có ngoại lệ:**
   - *Kích hoạt:* tiêu toàn bộ thanh Ultimate ngay lúc bấm, kể cả khi sau đó trượt
     hoặc bị ngắt.
   - *Startup:* nhìn thấy rõ (flash chỉ là trình bày, sim **không** dừng), dài hơn
     Heavy; **không có khung bất khả xâm phạm ở bất kỳ giai đoạn nào** — nên không
     dùng làm đòn phản công thoát combo được.
   - *Ngắt:* bị đánh trúng trong startup là Ultimate bị hủy, thanh đã tiêu không hoàn.
   - *Đỡ / né:* Block được; di chuyển ra khỏi tầm làm nó trượt.
   - *Freeze + cinematic chỉ khi trúng:* 60 tick freeze / cut-in (Tier 0; ≤150 tick ở
     Tier 1) chỉ phát khi Ultimate đánh trúng. Bị đỡ hoặc trượt thì không có freeze.
   - *Bị phạt:* bị đỡ hoặc trượt thì người dùng chịu recovery dài, đối thủ phạt được
     bằng combo đầy đủ.
   - *Cách trúng (ý đồ):* Ultimate **hủy (cancel) được từ một đòn trúng — không phải bị
     đỡ — đã xác nhận**, hitstun đảm bảo dài hơn startup nên combo kết bằng Ultimate chắc
     chắn trúng; counterplay của combo-Ultimate là đỡ/tránh đòn mở combo. Ngoài ra dùng
     để phạt một đòn trượt. Số liệu ở GDD Combat.
5. **AI đối thủ** — trạng thái hành vi, độ trễ phản ứng tính theo tick, RNG có seed
   trong state; Normal ở Tier 0, Easy/Hard ở Tier 1.

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | Chọn Operator/class và kiểu SP hợp phong cách; chọn khi nào kích hoạt kỹ năng | Supporting |
| **Competence** (mastery, skill growth) | Combo, nhịp SP, AI nhiều cấp, Training; tiến bộ là tiến bộ kỹ năng | Core |
| **Relatedness** (connection, belonging) | Versus với bạn bè (cùng máy, LAN); gắn bó với Operator yêu thích | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) — How: hạ AI Hard bằng từng Operator; làm chủ mọi class.
- [x] **Explorers** (discovery, understanding systems, finding secrets) — How: hiểu sâu tương tác giữa các kiểu SP và trạng thái kỹ năng; tìm route combo.
- [x] **Socializers** (relationships, cooperation, community) — How: phụ — đấu với bạn bè cùng máy/LAN.
- [x] **Killers/Competitors** (domination, PvP, leaderboards) — How: chính — thắng bạn bè trong Versus; không có ranked online.

Theo Quantic Foundry: nhóm chính là *Mastery* (Challenge + Strategy); nhóm phụ là
fan Arknights (động lực *Fantasy*). **Không dành cho:** người muốn cày cuốc/gacha,
người muốn ranked online, người chỉ muốn xem hiệu ứng mà không học cơ chế.

### Flow State Design

- **Onboarding curve**: Một nút một hành động (không motion input). 10 phút đầu:
  Quick Match vs AI Normal với Light/Heavy/Block; HUD hiển thị rõ SP và kỹ năng.
  Training (Tier 1) dạy combo và kiểu SP.
- **Difficulty scaling**: AI Easy → Normal → Hard (Tier 1); kỹ năng người chơi
  tăng theo việc học matchup và nhịp SP của đối thủ.
- **Feedback clarity**: Combo counter + tổng sát thương; tia va chạm màu class;
  thanh SP, thanh Ultimate và thời gian kỹ năng của **cả hai bên** luôn đọc được.
- **Recovery from failure**: Rematch tức thì; trận ngắn (3–5 phút); thua là bài
  học ("lẽ ra nên giữ kỹ năng thêm 2 giây").

---

## Core Loop

### Moment-to-Moment (30 seconds)

Tìm khoảng cách theo class (Sniper/Caster giữ xa, Guard áp sát), xác nhận đòn
trúng rồi nối Light → Heavy → Special. Mỗi hành động đồng thời nạp SP theo kiểu của
Operator, nên mỗi cú đánh vừa là sát thương vừa là quyết định về nhịp. Thỏa mãn vì:
phản hồi tức thì (hit-stop ngắn, trail, counter), input dễ, và luôn có câu hỏi
chiến thuật: đánh tiếp, lùi lại, hay đỡ để nạp?

### Short-Term (5-15 minutes)

Trận best-of-3, mỗi round 99 giây (5940 tick). Khi SP đầy, kích hoạt kỹ năng có thời
hạn; đối thủ phải né hoặc ép đánh để cắt nhịp. Ultimate là phần thưởng lớn nhất.
"Thêm một trận nữa" sinh ra từ những pha thua sát nút mà người chơi biết mình có
thể làm khác.

### Session-Level (30-120 minutes)

Quick Match vs AI, Versus cùng máy, Training (Tier 1), LAN với bạn bè (Tier 1).
Điểm dừng tự nhiên: sau mỗi trận, ở màn Rematch / Return to Menu. Lý do quay lại:
thử class khác, hoặc hạ được AI ở cấp khó hơn.

### Long-Term Progression

Không có cày cuốc hay mở khóa bằng tiền tệ. Tiến bộ là **kỹ năng của người chơi**:
học combo, học nhịp SP của từng Operator, leo độ khó AI. Operator Collection
(Tier 2) cung cấp thông tin và lore. "Xong game" = làm chủ mọi class và hạ AI Hard.

### Retention Hooks

- **Curiosity**: Operator chưa thử, matchup chưa hiểu, Operator mới ở tier sau.
- **Investment**: Gắn bó với Operator yêu thích từ Arknights.
- **Social**: Bạn bè cùng chơi Versus / LAN.
- **Mastery**: Combo khó hơn, AI Hard, thắng bạn bè.

---

## Game Pillars

**Ràng buộc cứng (không pillar nào ghi đè):** mọi trạng thái kỹ năng và Ultimate
phải chống trả được chỉ bằng **sàn counterplay** — Block, di chuyển, và ngắt bằng
đòn trúng. Thứ tự ưu tiên bên dưới chỉ áp dụng *phía trên* sàn này.

**Thứ tự ưu tiên:** khi quyết định **cơ chế**, 1 > 3 > 2 > 4. Khi quyết định
**trình bày** (tên gọi, UI, ngôn ngữ hình ảnh), Pillar 4 dẫn đầu — trừ độ dễ đọc
của HUD, nơi Pillar 3 thắng.

*Đã qua review CD-PILLARS (CONCERNS → đã sửa theo cả 4 góp ý) và `/design-review`
2026-10-31 (NEEDS REVISION → đã sửa → re-review APPROVED), rồi 2026-11-01 ba lần
NEEDS REVISION → đã sửa; 2026-11-09 lần 4 NEEDS REVISION → 3 dòng đã sửa → **APPROVED** (CD); xem `design/gdd/reviews/game-concept-review-log.md`.*

### Pillar 1: Class Is Identity
Class và kiểu nạp SP quyết định cách một Operator chơi, không chỉ chỉ số.

*Design test*: Một Operator mới phải khác các Operator đã có ở ít nhất một trong ba
điểm: tầm ưa thích, lúc SP vào, hoặc thời điểm muốn dùng kỹ năng. Nếu hai Operator
chơi giống nhau, ta thay đổi cơ chế chứ không chỉnh chỉ số.

### Pillar 2: Flow Into Burst — và mỗi cú bùng nổ đều có lời giải
Combo nhanh, mượt, luôn tích dần tới khoảnh khắc bùng nổ bằng kỹ năng — nhưng đối
thủ luôn có cách chống trả. Nhịp "trụ vững rồi bùng nổ" của Defender cũng là flow.

*Design test*: (a) Trạng thái kỹ năng nào mà đối thủ không thể thay đổi kết cục
chỉ bằng sàn counterplay (Block, di chuyển, ngắt bằng đòn trúng), mà chỉ có thể ngồi
chờ hết giờ, thì bị loại. (b) Khi nhịp độ và phần thưởng mâu thuẫn, nhịp độ thắng.
Cũng vậy với **tốc độ và trọng lượng đòn**: tốc độ thắng; trọng lượng đến từ hit-stop
và âm thanh, không đến từ recovery dài (recovery dài như rủi ro bị phạt cho Throw
trượt / Ultimate bị đỡ là hợp lệ; cấm dùng nó để tạo cảm giác nặng).

### Pillar 3: Readable Mastery
Chiều sâu đến từ các hệ thống học được và nhìn thấy được **của cả hai bên**: SP,
kiểu SP, thanh Ultimate và thời gian kỹ năng còn lại của đối thủ phải đọc được ngay
cả khi chưa giao tranh.

*Design test*: Giữa hoành tráng và rõ ràng, chọn rõ ràng. Độ dễ đọc của HUD thắng
cả Pillar 4.

### Pillar 4: Rhodes Island Faithful (trình bày)
Một Doctor nhận ra ngay qua tên gọi, giao diện công nghệ quân sự, ngôn ngữ class và
kiểu SP — với toàn bộ asset là bản gốc. Về cơ chế, pillar này nhường cho Pillar 1–3:
Doctor nhận ra ý tưởng, còn game đối kháng quyết định con số.

*Design test*: Phân vân về trình bày thì chọn phương án mà một Doctor nhận ra được;
phân vân về cơ chế thì pillar này không được dùng để phá vỡ cân bằng (vd. không dùng
thời lượng kỹ năng 20–40 giây của bản gốc).

### Anti-Pillars (What This Game Is NOT)

- **NOT gacha / tiền tệ mở khóa / cày cuốc**: Bảo vệ nguyên tắc "tiến bộ = kỹ năng"
  (Pillar 3) và tránh sự lặp lại máy móc người dùng không thích.
- **NOT Operator nông để đủ số lượng**: Số Operator là *kết quả* của design test
  Pillar 1, không bao giờ là mục tiêu; thà ít mà sâu.
- **NOT motion input (↓↘→ + nút)**: Bàn phím và người mới cần một nút một hành động
  (Pillar 2, 3). **Được phép** tổ hợp hướng + nút (vd. ↓+K) để bộ chiêu đủ dày cho
  Pillar 1.
- **NOT cinematic Ultimate dài quá 2,5 giây**: Dài hơn sẽ phá nhịp (Pillar 2).
- **NOT online ranked / matchmaking / server**: Chỉ cùng máy và LAN IP trực tiếp.
- **NOT Tag Versus trong bất kỳ tier đã lên kế hoạch**: Nhân đôi độ phức tạp ở sim,
  UI, AI và netcode; cần quyết định phạm vi riêng.

---

## Visual Identity Anchor

**Hướng: Tactical Dossier + Silhouette Doctrine** *(AD-CONCEPT-VISUAL: STRONG)*

**Quy tắc một dòng:** *Màu sắc là thông tin — thế giới là đen, vàng đồng, trắng;
chỉ trạng thái gameplay mới có màu. Và mọi class phải nhận ra được qua hình dáng
trong ảnh đen trắng.*

**Nguyên tắc hỗ trợ**

1. **Feed tác chiến Rhodes Island.** UI dùng khung bracket, hình chữ nhật vát góc
   45°, chevron, ô lục giác, chữ monospace, sọc cảnh báo, scanline nhẹ khi chuyển
   cảnh. Đấu trường giảm độ bão hòa (~30%) và hơi mờ để nhân vật nổi bật.
   *Design test:* nếu một chi tiết trang trí cạnh tranh sự chú ý với nhân vật hoặc
   HUD, nó bị giảm hoặc bỏ.
2. **Silhouette theo class (luật bắt buộc cho Operator và hiệu ứng).** Defender =
   khối vuông, tường; Guard = vòng cung lưỡi kiếm; Vanguard = chevron hướng tới;
   Sniper = đường dài mảnh, tâm ngắm; Caster = vòng tròn, vòng rune; Medic = chữ
   thập mềm; Supporter = lưới lục giác; Specialist = móc, zigzag chéo.
   *Design test:* chụp màn hình đen trắng — không nhận ra class thì sửa hình dáng,
   không sửa màu.
3. **Leo thang có kiểm soát.** Khi kỹ năng kích hoạt, màu class của Operator đó lan
   vào trail và viền màn hình, rồi trở về trung tính khi hết thời gian kỹ năng.
   Rung màn hình và slow-motion chỉ áp lên lớp thế giới, không bao giờ lên HUD.
   *Design test:* trong lúc bùng nổ, HUD của đối thủ vẫn phải đọc được.

**Triết lý màu**

- Trung tính (đen ~#121212, trắng ngà, vàng đồng) thuộc về khung, HUD và thế giới.
- Mỗi class một màu nhấn cố định: Vanguard đỏ cam, Guard hổ phách, Defender xanh
  thép, Sniper xanh lá, Caster tím, Medic xanh lam nhạt, Supporter xanh mòng két,
  Specialist hồng tím. Dùng trên thanh SP, hào quang kỹ năng, tia va chạm, tông
  cinematic Ultimate.
- P1 / P2 phân biệt bằng khung trắng / khung đồng và marker bên, không bằng màu —
  trận cùng nhân vật vẫn dễ đọc.
- Đỏ chỉ dành cho nguy hiểm và sát thương sắp tới.

**Tạo hình nhân vật:** chibi khoảng **3 đầu** (không phải 2) để tầm đánh đọc được;
một đạo cụ class quá khổ (khiên, trượng, cung) là chìa khóa silhouette; **sprite 2D
vẽ tay, nét viền rõ** (thay cho khối vát cạnh + toon shader + outline inverted-hull,
quyết định 2026-11-10); trail thể hiện đúng tầm thật của đòn.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Granblue Fantasy Versus | Input đơn giản (hướng + nút), anime 2.5D, dễ vào mà sâu | SP theo kiểu class thay cho thanh chung; kỹ năng là trạng thái có thời hạn | Chứng minh game đối kháng dễ vào vẫn có cộng đồng cạnh tranh |
| Dragon Ball FighterZ | Nhịp nhanh, combo mượt, cinematic tuyệt kỹ | Cinematic ngắn (≤2,5 giây), không bao giờ che HUD | Chứng minh fan IP anime đón nhận game đối kháng |
| Under Night In-Birth | Tài nguyên nạp theo hành động (GRD) tạo lớp chiến thuật | Mỗi Operator một quy tắc nạp khác nhau | Chứng minh tài nguyên gắn hành động tạo chiều sâu |
| Street Fighter 6 | Hệ thống phòng thủ (Drive Parry ~ Perfect Guard), độ rõ ràng của HUD | Không motion input bắt buộc | Chuẩn mực về phản hồi và cảm giác đòn |
| Arknights | Class, kiểu SP, kỹ năng có thời hạn, UI công nghệ quân sự | Chuyển từ tower defense sang đối kháng; con số do game đối kháng quyết định | Nguồn nhận diện của Pillar 4 |

**Non-game inspirations**: Ngôn ngữ hình ảnh của hồ sơ tác chiến quân sự và màn
hình chỉ huy; các phân cảnh hành động anime (cut-in, speed line) dùng có chừng mực.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 16–30 |
| **Gaming experience** | Mid-core |
| **Time availability** | Phiên 30–60 phút buổi tối; lâu hơn khi chơi cùng bạn bè cuối tuần |
| **Platform preference** | PC |
| **Current games they play** | Arknights, Granblue Fantasy Versus / DBFZ, game hành động |
| **What they're looking for** | Điều khiển trực tiếp Operator yêu thích trong một game đối kháng có chiều sâu |
| **What would turn them away** | Gacha / cày cuốc; input phức tạp; hiệu ứng che mất trận đấu; nhân vật không ra chất Arknights |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | **Godot 4.7.2 + GDScript** (chọn qua `/setup-engine` 2026-10-31; cài đặt và test runner gdUnit4 đã kiểm chứng). Yêu cầu bắt buộc (TD-FEASIBILITY), áp vào Godot: sim là GDScript thuần (không Node, không PhysicsServer), tự step theo tick 60 Hz, step thủ công nhiều lần mỗi frame; state phẳng (Packed array); snapshot là bản copy tường minh vào bộ đệm cấp phát sẵn (Packed array gán là alias — ADR-0002), ngân sách ≤ 0,25 ms mỗi tick gồm cả snapshot + checksum (ADR-0001, **chưa đo** — kiểm V5); `PacketPeerUDP` cho LAN; số học fixed-point số nguyên (ADR-0001). Nên có: hot reload dữ liệu chiêu (chỉ ngoài trận), overlay debug-draw hitbox, input tách theo InputMap action cho từng người chơi, toon/outline shader, glow/halo theo art bible §8.9 (không bật glow của WorldEnvironment). |
| **Key Technical Challenges** | Mô phỏng tất định (hit-stop, slow-mo, cinematic không được dùng time scale của engine); netcode game đối kháng qua LAN ảo; khối lượng animation; công cụ frame data; input buffer/cancel/ưu tiên đòn; ghosting khi 2 người chung bàn phím |
| **Art Style** | **2D sprite** (chibi ~3 đầu, nét viền rõ, màu phẳng) — quyết định 2026-11-10, thay cho 2.5D 3D stylized |
| **Art Pipeline Complexity** | High (sprite tự vẽ, từng khung) — chi phí chính là số khung mỗi đòn; animation chỉ để trình bày. Mọi sprite là bản gốc tự vẽ, không lấy hình từ game |
| **Audio Needs** | Moderate — nhạc menu, nhạc đấu trường, SFX đòn đánh / kỹ năng / UI; volume nhạc và SFX tách riêng |
| **Networking** | P2P qua LAN / LAN ảo (Hamachi, Radmin), IP trực tiếp, UDP; delay-based trước, thiết kế state sẵn cho rollback |
| **Content Volume** | Tier 0: 2 Operator × 10–12 animation sprite, 1 đấu trường 2D. Full vision: 10 Operator, 7 đấu trường |
| **Procedural Systems** | Không có procedural generation; model placeholder dựng từ khối cơ bản |

**Ghi chú kiến trúc bắt buộc từ ngày đầu (TD-FEASIBILITY):**
- Sim 60 Hz cố định, chỉ đồng bộ input; mọi thời gian tính bằng tick (8 giây = 480
  tick, 99 giây = 5940 tick).
- Hitbox là dữ liệu theo frame trong file ngoài, kiểm tra overlap trong code sim;
  không dùng physics hay collider của engine.
- Hit-stop là bộ đếm trong sim; slow-mo chỉ là hiệu ứng trình bày; cinematic Ultimate
  do sim giữ số frame freeze, camera chỉ đọc.
- RNG của AI có seed nằm trong state.
- Ghi/phát lại input kèm checksum mỗi tick từ Tier −1, chạy trong CI.
- Mô hình số: **fixed-point số nguyên**, quyết định bởi ADR-0001
  (`docs/architecture/adr-0001-sim-numeric-model.md`, Proposed — chờ Accepted). **Mọi tài
  nguyên và bộ đếm gameplay (HP, SP, thanh Ultimate, thời gian) là số nguyên.**

---

## Risks and Open Questions

### Design Risks
- Cân bằng giữa ba kiểu SP: Offensive có thể lấn át (snowball), Defensive có thể
  dẫn tới chơi thủ mãi (turtling).
- Trạng thái kỹ năng có thời hạn có thể biến thành "chạy trốn chờ hết giờ" nếu
  thiếu counterplay (chặn bằng sàn counterplay + design test của Pillar 2).
- **Chống câu giờ:** Throw thắng Block (chống chơi thủ của Defensive); hết giờ thì
  bên có **% HP cao hơn** thắng round. Không có cơ chế lội ngược dòng riêng.
  **Cổng bắt buộc:** GDD Combat phải giải quyết việc Amiya (Auto-SP) đánh một đòn rồi
  kiting tới hết giờ trong matchup Ch'en vs Amiya — **kể cả thanh Ultimate**, vì Auto
  nạp cả SP lẫn Ultimate theo tick mà không cần giao tranh — viết thành acceptance criterion
  (kể cả đấu trường có tường hay không), **trước khi** bắt đầu phần Amiya trong Combat Slice — không để
  playtest phát hiện, không hoãn lần nữa.
- Không có motion input có thể làm bộ chiêu mỏng; giảm bằng tổ hợp hướng + nút.
- AI Normal vui để đánh là bài toán tinh chỉnh, không chỉ là lập trình.

### Technical Risks
- **TD-FEASIBILITY: CONCERNS.** Concept khả thi; thành công phụ thuộc vào kỷ luật
  tính tất định, giới hạn animation và coi Tier 0 là mục tiêu thật.
- Tính tất định bị phá ngầm (time scale, physics, RNG toàn cục, delta time).
- Netcode qua Hamachi/Radmin (20–80 ms, khoảng 1–5 frame một chiều); broadcast
  discovery thường hỏng trên adapter ảo; hộp thoại Windows Firewall.
- Animation sprite không có họa sĩ: mỗi đòn là nhiều khung vẽ tay; chi phí mỗi animation đo ở spike art 2D.
- Ghosting bàn phím khi 2 người chung máy → hỗ trợ gamepad từ Tier 0.
- **Sẽ thành HIGH RISK nếu:** đưa online/rollback vào Tier 0; dùng physics hoặc
  collider theo animation cho hitbox; cam kết roster Tier 2 hoặc Tag Versus trước
  khi Tier 0 xong; bỏ qua Tier −1, hoặc bắt đầu Amiya trước khi Ch'en khối hộp
  chạy ổn trong Combat Slice.

### Market Risks
- Fan game dùng IP Arknights: không thể bán, không thể lên Steam; chỉ chia sẻ miễn
  phí, vẫn có rủi ro bị yêu cầu gỡ. Kiểm tra quy định fan content của Hypergryph.
- Không có mục tiêu thương mại; "thành công" = bạn bè và cộng đồng fan chơi được.

### Scope Risks
- **PR-SCOPE: OPTIMISTIC** (đã áp dụng điều chỉnh). Ước tính ban đầu 3–4 tháng cho
  MVP ngắn hơn thực tế 1,5–2 lần.
- Học engine chưa có trong ước tính (3–6 tuần) — Tier −1 là giai đoạn học.
- Khối lượng animation là chỗ dễ trễ nhất (1–3 ngày mỗi animation cho người mới).
- Tinh chỉnh cảm giác đòn không có điểm dừng → timebox mỗi Operator.
- Chi phí tài liệu ở rigor `full` (~15–25%) → xem lại sau Tier −1.
- Kiệt sức khi làm một mình lâu dài → mỗi tier kết thúc bằng một bản chơi được,
  có retrospective.

### Open Questions
- **Surtr thay Ch'en hay là nhân vật thứ ba của Tier 0?** *(Quyết định 2026-11-11, user:
  nhân vật đầu tiên được vẽ và dựng là **Surtr**, vẽ tay bằng Krita, thiết kế gốc theo
  art bible §8.11 / §9.)* Concept chưa nói Surtr **thay** Ch'en (Guard, Offensive SP,
  cận chiến) hay **thêm vào** roster Tier 0 (Ch'en + Amiya). **Đề xuất: thay Ch'en** —
  giữ Tier 0 ở 2 nhân vật; thêm người thứ ba phá luật "không mở rộng roster trước gate
  Combat Slice". Roster ở các mục khác chưa sửa cho tới khi user chọn.
- **Float có kiểm soát hay fixed-point?** → đã chọn fixed-point số nguyên (ADR-0001, Proposed).
- ~~**Model khối cứng hay skinned mesh?**~~ → không còn áp dụng: game chuyển sang 2D sprite
  (2026-11-10). Câu hỏi mới: độ phân giải sprite và số khung mỗi đòn → spike art 2D.
- **LAN qua Hamachi có chơi được không?** → spike LAN 1 tuần cuối Tier −1.
- **Cảm giác đòn có "nhanh và mượt" không?** → đo ở Combat Slice (Tier −1 chỉ chứng
  minh nền móng). Prototype mirror-feel 2026-11-01: chưa có bằng chứng lưu lại — không
  trích dẫn như đã kiểm chứng.
- **Ngày mục tiêu Tier 0?** → đặt sau Tier −1, theo tốc độ thực tế.

---

## MVP Definition

**Core hypothesis**: Combo nhanh kết hợp với hai kiểu nạp SP khác nhau (Offensive
cận chiến vs Auto tầm xa) tạo ra những trận đấu 1v1 mà người chơi muốn "thêm một
trận nữa".
*Đo bằng:* **gate Combat Slice** (bên dưới) — đây là gate của giả thuyết. Cuối Tier 0
đo lại cùng tiêu chí với người thử mới để xác nhận, không phải một gate thứ hai.

**Bước trước MVP — Tier −1 vertical slice (4–6 tuần, tối đa 9):** 1 Operator đánh
gương; Light/Heavy/Block; nhân vật là khối hộp; một mặt phẳng đấu trường; sim tất
định + ghi/phát lại input kèm checksum; spike LAN 1 tuần (2 PC gửi input qua UDP,
thử trên Hamachi). *Điều kiện qua:* hai người chơi được một trận; cùng một file
replay cho ra cùng checksum mỗi lần chạy. Quá 9 tuần → lên lại kế hoạch Tier 0.
Qua Tier −1 nghĩa là **nền móng dùng được**, không phải giả thuyết cốt lõi đã được
chứng minh — giả thuyết chỉ được đo ở gate Combat Slice.

**Mốc đầu Tier 0 — Combat Slice (quyết định 2026-11-01):** bắt đầu *sau khi Tier −1
qua*. Nội dung: Ch'en + Amiya, Lungmen Street 2D, combat đầy đủ (đòn riêng từng
Operator, Throw, SP + kỹ năng, Ultimate), HUD combat, Victory/Defeat, Rematch. Người
đấu người; không có AI, LAN, Training, Settings. Perfect Guard/Dodge: không có trong
Combat Slice; quyết ở gate của slice. Làm theo 3 chặng: (a) Ch'en khối hộp, (b) Amiya +
projectile, (c) art sprite 2D + Ultimate sau cùng. **Không mở rộng roster** trước khi Combat
Slice qua gate.
**Gate Combat Slice** (người quyết: user): timebox 10–14 tuần, **tính từ ngày ghi nhận
Tier −1 PASS**; checkpoint tuần 7. Mỗi cặp dùng chung một nút Rematch, nên chấm **theo
cặp**. *Bảng thử:* 3 cặp, mỗi cặp được dành sẵn một phiên 30 phút, không bắt buộc chơi hết; "người mới" = chưa từng thấy game,
ghi nhận trước phiên. *Rematch không được nhắc:* bấm Rematch trong **10 giây** sau màn
Victory, người quan sát không gợi ý gì (chỉ nói "chơi bao lâu tùy thích").
*PASS:* ≥2/3 cặp có Rematch không được nhắc, trong đó ≥1 cặp gồm hai người mới.
*Hỏng phiên:* crash hoặc desync trước phút 30 thì cặp đó chơi lại; phiên crash không
bao giờ tính là pass. *FAIL:* retrospective thiết kế → **một** lần tinh chỉnh (tối đa
4 tuần) rồi chạy lại gate **một** lần với 3 cặp mới hoàn toàn, cùng tiêu chí. FAIL lần
hai → pivot; roster vẫn đóng băng. Kết quả thô ghi vào `/playtest-report` trước khi quyết.
3 cặp là tín hiệu định hướng, không phải bằng chứng thống kê.
*Gate không phụ thuộc chặng (c):* playtest chạy được với model/animation blockout (phần
sim của Ultimate vẫn có), nhưng đòn trúng phải có hit-stop và SFX tạm; art sprite và cinematic Ultimate nếu chưa xong thì làm sau gate,
không kéo dài timebox.

**Required for MVP (Tier 0)**:
1. **2 Operator khác kiểu SP**: Ch'en (Guard, Offensive, cận chiến) và Amiya
   (Caster, Auto, projectile); 10–12 animation mỗi Operator (đã tính Throw, bị ném
   và throw tech), rig dùng chung.
2. **Combat lõi**: Light/Heavy/Air/Special, tổ hợp hướng + nút, hitbox/hurtbox từ
   dữ liệu, hitstun, knockback, hit-stop, combo counter + tổng sát thương.
3. **SP theo kiểu + một kỹ năng có thời hạn** cho mỗi Operator.
4. **Ultimate bản đơn giản** (60 tick khi trúng: freeze, camera đẩy vào, cut-in chân
   dung), dùng thanh Ultimate riêng nạp theo kiểu SP; startup đỡ/ngắt/phạt được như
   Core Mechanics mục 4.
5. **Phòng thủ**: sàn counterplay (Block, di chuyển, ngắt bằng đòn trúng) + vòng tam
   giác Throw kèm throw tech — không bao giờ cắt; Perfect Guard và Dodge (không có
   trong Combat Slice; quyết ở gate của slice; nếu không làm trong Tier 0 thì là mục
   cắt đầu tiên).
6. **1 đấu trường**: Lungmen Street.
7. **Chế độ**: Versus 2 người cùng máy, Quick Match vs AI Normal (AI Normal là
   mục cắt dự phòng thứ 2; playtest Tier 0 là người thử đấu người thử).
8. **Luồng trận**: màn chọn Operator tối giản, HUD đầy đủ (HP, SP + kiểu SP, thanh Ultimate,
   thời gian kỹ năng của cả hai bên, đồng hồ, số round thắng), BEGIN, K.O., Rematch / Return to Menu.
9. **Input**: bộ phím mặc định cho 2 người chung bàn phím (hai cụm phím cách xa
   nhau) + hỗ trợ gamepad.

**Phương án dự phòng Tier 0:** giữ Ch'en + Amiya; thứ tự cắt: Perfect Guard/Dodge → AI Normal → Air attack
(Ultimate đã là bản đơn giản nên không cắt gì thêm ở đó). Giả thuyết cốt lõi đo bằng người đấu người, nên AI
cắt trước Air attack (CD-SYSTEMS 2026-11-01); slot "AI ghi input word" trong Sim Core vẫn giữ. Không cắt xuống 1 Operator — cặp cận chiến đối đầu caster mới chứng
minh được concept.

**Explicitly NOT in MVP** (defer to later):
- LAN multiplayer (Tier 1; đã spike ở Tier −1)
- Mudrock và mọi Operator thứ ba trở đi
- AI Easy / Hard, Training mode, Settings (đổi phím, âm lượng, đồ họa)
- Cinematic Ultimate đầy đủ (≤2,5 giây)
- Màn chọn đấu trường, đấu trường thứ hai trở đi
- Operator Collection, Tag Versus

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **Tier −1: Vertical Slice** | 1 Operator (khối hộp), 1 mặt phẳng đấu trường | Light/Heavy/Block, sim tất định, replay + checksum, spike LAN | 4–6 tuần (tối đa 9) |
| **Tier 0a: Combat Slice** (mốc đầu Tier 0) | Ch'en, Amiya; Lungmen Street 2D | Combat đầy đủ, HUD combat, Victory/Defeat, Rematch; không AI/LAN/Training/Settings | 10–14 tuần (nằm trong Tier 0) |
| **Tier 0: MVP** | Ch'en, Amiya; Lungmen Street | Như "Required for MVP" | +3,5–7 tháng (dự kiến 5); tổng tới MVP ~6,5 tháng |
| **Tier 1: Chơi với bạn bè** | +Mudrock (cuối cùng) | Theo thứ tự: Settings → Training → LAN delay-based → AI Easy/Hard → cinematic đầy đủ → Mudrock | +2,5–5 tháng (dự kiến 3,5) |
| **Tier 2: Full Vision** (danh sách mong muốn) | Tối đa 10 Operator, 7 đấu trường | Operator Collection, cinematic cho mọi Operator, màn chọn đấu trường đầy đủ | 30+ tháng tổng (solo) |

Độ tin cậy ước tính: **thấp** (engine mới chọn và chưa có kinh nghiệm dùng, chưa có dữ liệu tốc độ). Sau Tier −1,
đặt ngày mục tiêu Tier 0 cụ thể (± 4 tuần). Nếu hết thời gian: phát hành Tier 0 +
phần đầu Tier 1 (bao gồm LAN).

---

## Next Steps

- [x] Get concept approval from creative-director (CD-PILLARS: CONCERNS → đã sửa)
- [x] Fill in CLAUDE.md technology stack based on engine choice (`/setup-engine`) — Godot 4.7.2 / GDScript
- [x] Validate the concept and its pillars (`/design-review`) — NEEDS REVISION → revised 2026-10-31; re-review 2026-10-31: NEEDS REVISION (Throw counter, Ultimate counterplay) → revised → APPROVED; 2026-11-01: NEEDS REVISION ×3 → revised; 2026-11-09 lần 4: NEEDS REVISION → 3 dòng đã sửa (Ultimate thô vs combo, phiên 30 phút không bắt buộc, blockout có hit-stop + SFX tạm) → **APPROVED** (CD)
- [x] Viết `/art-bible` từ Visual Identity Anchor — `design/art/art-bible.md`
- [x] Decompose concept into systems (`/map-systems`) — xong 2026-11-01: `design/gdd/systems-index.md`. Theo PR-SCOPE (điều chỉnh A): Tier −1 dùng prototype brief + ADR (mô hình số, tách sim/view). **Quyết định 2026-11-01:** GDD được viết nháp song song với Tier −1; Formulas và Tuning Knobs ghi *provisional* tới khi có dữ liệu Tier −1; GDD Sim Core, Movement, Hit Detection chỉ là nháp tới khi ADR-0001/0002 Accepted. GDD Combat phải xong và qua review trước Combat Slice
- [ ] **Prototype core idea** — Tier −1 vertical slice (`/prototype` đánh gương 1 Operator); chốt quy tắc PROCEED/PIVOT/KILL đo được trước khi chạy
- [ ] Design each system (`/design-system [system-name]`) — use prototype learnings in Tuning Knobs and Formulas sections
- [ ] Viết và review GDD Combat (`/design-system` → `/design-review`) — bắt buộc trước chặng (a) của Combat Slice
- [ ] Build Combat Slice (mốc đầu Tier 0) và qua gate Combat Slice — thay cho `/vertical-slice`
- [ ] Validate core loop with playtest (`/playtest-report`)
- [ ] Plan first milestone (`/sprint-plan new`)
- [ ] Xem lại `modes.rigor` sau Tier −1
