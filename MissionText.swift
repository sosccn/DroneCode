import Foundation

struct MissionText {
    let name: [String: String]
    let goal: [String: String]
    let brief: [String: String]
}

private let missionText_basic = MissionText(name: ["th": "บทที่ 1 · บินขึ้นและลงจอด", "en": "Lesson 1 - Take off and land"],
        goal: ["th": "สั่งให้โดรนบินขึ้น ลอยนิ่ง แล้วลงจอด", "en": "Take off, hover, then land safely"],
        brief: ["th": "<h3>บทที่ 1 · บินขึ้นและลงจอด</h3><p>ทุกโปรแกรมเริ่มจากบล็อก <code>when program starts</code> แล้วต่อคำสั่งลงมาเป็นลำดับจากบนลงล่าง</p><ol><li>ลาก <code>take off</code> จากหมวด Flight มาต่อใต้บล็อกเริ่มโปรแกรม</li><li>ต่อด้วย <code>hover for 2 seconds</code></li><li>ปิดท้ายด้วย <code>land</code> แล้วกดรันโปรแกรม</li></ol><div class=\"note\"><b>รู้ไหม</b> คำสั่ง takeoff ของโดรนจริงจะยกตัวขึ้นราว 1 เมตรแล้วลอยรอคำสั่งถัดไป ถ้าสั่งบินทั้งที่ยังไม่ takeoff โดรนจะขึ้นสถานะ error</div>",
                "en": "<h3>Lesson 1 - Take off and land</h3><p>Every program starts from the <code>when program starts</code> block and runs top to bottom.</p><ol><li>Drag <code>take off</code> from the Flight category under the start block</li><li>Add <code>hover for 2 seconds</code></li><li>Finish with <code>land</code> and press Run</li></ol><div class=\"note\"><b>Did you know</b> a real Tello climbs to about 1 m on takeoff and waits there. Commanding a move before takeoff returns an error.</div>"])

private let missionText_line = MissionText(name: ["th": "บทที่ 2 · บินไปและกลับที่เดิม", "en": "Lesson 2 - Out and back"],
        goal: ["th": "บินไปข้างหน้า 1 เมตรแล้วกลับมาลงจอดจุดเดิม", "en": "Fly 1 m forward and return to the pad"],
        brief: ["th": "<h3>บทที่ 2 · บินไปและกลับที่เดิม</h3><p>บล็อก <code>fly forward 100 cm</code> มีเมนูเลือกทิศ 6 ทิศ และช่องระยะทางหน่วยเซนติเมตร (20 ถึง 500 เท่าโดรนจริง)</p><ol><li>take off</li><li>fly forward 100 cm</li><li>fly back 100 cm</li><li>land</li></ol><div class=\"note\"><b>เกณฑ์ผ่าน</b> ต้องบินห่างจุดเริ่มอย่างน้อย 90 ซม. และกลับมาลงจอดห่างจุดเดิมไม่เกิน 40 ซม.</div>",
                "en": "<h3>Lesson 2 - Out and back</h3><p>The <code>fly</code> block has six directions and a distance in centimetres (20 to 500, same as the real drone).</p><ol><li>take off</li><li>fly forward 100 cm</li><li>fly back 100 cm</li><li>land</li></ol><div class=\"note\"><b>To pass</b> fly at least 90 cm away and land within 40 cm of the pad.</div>"])

private let missionText_square = MissionText(name: ["th": "บทที่ 3 · บินสี่เหลี่ยมด้วยลูป", "en": "Lesson 3 - Square with a loop"],
        goal: ["th": "ใช้บล็อก repeat บินเป็นสี่เหลี่ยมผ่านห่วงครบ 4 วง", "en": "Use a repeat loop to fly a square through all 4 gates"],
        brief: ["th": "<h3>บทที่ 3 · บินสี่เหลี่ยมด้วยลูป</h3><p>แทนที่จะเขียนคำสั่งซ้ำ 4 ชุด ใช้ <code>repeat 4 times</code> จากหมวด Loops ครอบคำสั่งไว้ข้างใน</p><ol><li>take off</li><li>repeat 4 times { fly forward 150 cm, rotate clockwise 90 degrees }</li><li>land</li></ol><div class=\"note\"><b>เกณฑ์ผ่าน</b> ผ่านห่วงครบ 4 วง ใช้บล็อก repeat และลงจอด</div>",
                "en": "<h3>Lesson 3 - Square with a loop</h3><p>Instead of repeating four sets of blocks, wrap them in <code>repeat 4 times</code> from the Loops category.</p><ol><li>take off</li><li>repeat 4 times { fly forward 150 cm, rotate clockwise 90 degrees }</li><li>land</li></ol><div class=\"note\"><b>To pass</b> clear all 4 gates, use the repeat block and land.</div>"])

private let missionText_course = MissionText(name: ["th": "บทที่ 4 · สนามห่วง 3 ระดับ", "en": "Lesson 4 - Three level gate course"],
        goal: ["th": "ผสมคำสั่งขึ้น ลง และหมุน ให้ผ่านห่วงทั้ง 3 วง", "en": "Mix up, down and turn commands to clear 3 gates"],
        brief: ["th": "<h3>บทที่ 4 · สนามห่วง 3 ระดับ</h3><p>ห่วงอยู่คนละความสูงและคนละทิศ ต้องผสมคำสั่งขึ้นลงกับการหมุนตัว</p><ol><li>take off</li><li>fly down 40 cm แล้ว fly forward 120 cm</li><li>fly up 100 cm แล้ว fly forward 120 cm</li><li>rotate counter-clockwise 90 แล้ว fly forward 120 cm</li><li>land</li></ol><div class=\"note\"><b>เคล็ดลับ</b> ดูค่าความสูง Y และตำแหน่ง X/Z ในแถบเทเลเมทรีเพื่อตรวจว่าโดรนอยู่ตรงไหน</div>",
                "en": "<h3>Lesson 4 - Three level gate course</h3><p>The gates sit at different heights and headings, so combine altitude changes with turns.</p><ol><li>take off</li><li>fly down 40 cm then fly forward 120 cm</li><li>fly up 100 cm then fly forward 120 cm</li><li>rotate counter-clockwise 90 then fly forward 120 cm</li><li>land</li></ol><div class=\"note\"><b>Tip</b> watch the X, Y and Z telemetry to know exactly where the drone is.</div>"])

private let missionText_show = MissionText(name: ["th": "บทที่ 5 · โชว์ตีลังกาและไฟ LED", "en": "Lesson 5 - Flip and LED show"],
        goal: ["th": "ตั้งไฟ LED และตีลังกาอย่างน้อย 1 ครั้ง", "en": "Set the LED and perform at least one flip"],
        brief: ["th": "<h3>บทที่ 5 · โชว์ตีลังกาและไฟ LED</h3><p>โดรนรุ่นการศึกษาอย่าง Tello EDU และ RoboMaster TT มีไฟ LED และคำสั่ง flip ในตัว</p><ol><li>take off แล้ว fly up 50 cm เผื่อระยะปลอดภัย</li><li>set LED to purple</li><li>flip forward</li><li>land</li></ol><div class=\"note\"><b>ข้อควรรู้</b> โดรนจริงจะไม่ยอมตีลังกาถ้าแบตต่ำหรือความสูงไม่พอ ในห้องเรียนนี้จำลองเงื่อนไขความสูงไว้ที่ 80 ซม.</div>",
                "en": "<h3>Lesson 5 - Flip and LED show</h3><p>Education drones such as the Tello EDU and RoboMaster TT have an LED and a built in flip command.</p><ol><li>take off then fly up 50 cm for clearance</li><li>set LED to purple</li><li>flip forward</li><li>land</li></ol><div class=\"note\"><b>Note</b> a real drone refuses to flip on a low battery or without clearance. Here the altitude limit is simulated at 80 cm.</div>"])

private let missionText_sensor = MissionText(name: ["th": "บทที่ 6 · เซ็นเซอร์และเงื่อนไข", "en": "Lesson 6 - Sensors and conditions"],
        goal: ["th": "บินเข้าหากำแพงแล้วหยุดก่อนชนด้วยเงื่อนไข", "en": "Fly toward the wall and stop before hitting it"],
        brief: ["th": "<h3>บทที่ 6 · เซ็นเซอร์และเงื่อนไข</h3><p>บล็อก <code>obstacle within 100 cm ahead</code> และ <code>get front distance</code> จำลองเซ็นเซอร์วัดระยะด้านหน้า ใช้คู่กับ <code>repeat until</code> หรือ <code>if</code> ได้</p><ol><li>take off</li><li>repeat until (obstacle within 100 cm ahead) { fly forward 20 cm }</li><li>rotate clockwise 90 degrees แล้ว land</li></ol><div class=\"note\"><b>เกณฑ์ผ่าน</b> ต้องหยุดห่างกำแพง 60 ถึง 140 ซม. ห้ามชน และต้องใช้บล็อกเงื่อนไข</div>",
                "en": "<h3>Lesson 6 - Sensors and conditions</h3><p>The blocks <code>obstacle within 100 cm ahead</code> and <code>get front distance</code> simulate a forward range sensor. Combine them with <code>repeat until</code> or <code>if</code>.</p><ol><li>take off</li><li>repeat until (obstacle within 100 cm ahead) { fly forward 20 cm }</li><li>rotate clockwise 90 degrees then land</li></ol><div class=\"note\"><b>To pass</b> stop between 60 and 140 cm from the wall without crashing, using a condition block.</div>"])

private let missionText_variables = MissionText(name: ["th": "บทที่ 7 · ตัวแปรและลูปนับรอบ", "en": "Lesson 7 - Variables and counting loops"],
        goal: ["th": "ใช้ count with i และตัวแปรไต่ระดับให้สูงถึง 250 ซม.", "en": "Use a counting loop and a variable to climb past 250 cm"],
        brief: ["th": "<h3>บทที่ 7 · ตัวแปรและลูปนับรอบ</h3><p>บล็อก <code>count with i from 1 to 4 by 1</code> จะเก็บรอบปัจจุบันไว้ในตัวแปร <code>i</code> ดึงค่ามาใช้ด้วยบล็อก <code>i</code> จากหมวด Variables</p><ol><li>take off</li><li>count with i from 1 to 4 by 1 { fly up (i x 20) cm }</li><li>hover for 1 second แล้ว land</li></ol><div class=\"note\"><b>เกณฑ์ผ่าน</b> ใช้บล็อก count with i และไต่ระดับได้สูงอย่างน้อย 250 ซม. แล้วลงจอด</div>",
                "en": "<h3>Lesson 7 - Variables and counting loops</h3><p>The <code>count with i from 1 to 4 by 1</code> block stores the current round in the variable <code>i</code>. Read it with the <code>i</code> block from the Variables category.</p><ol><li>take off</li><li>count with i from 1 to 4 by 1 { fly up (i x 20) cm }</li><li>hover for 1 second then land</li></ol><div class=\"note\"><b>To pass</b> use the counting loop, climb to at least 250 cm and land.</div>"])

private let missionText_free = MissionText(name: ["th": "โหมดอิสระ · สนามซ้อมเปล่า", "en": "Free mode - open arena"],
        goal: ["th": "ทดลองบล็อกทุกแบบได้ตามใจ ไม่มีเงื่อนไขผ่าน", "en": "Try every block, no pass condition"],
        brief: ["th": "<h3>โหมดอิสระ · สนามซ้อมเปล่า</h3><p>ไม่มีภารกิจบังคับ เหมาะกับการทดสอบโปรแกรมก่อนนำไปใช้กับโดรนจริง</p><ul><li><code>go to x y z</code> บินตรงไปยังพิกัดในคำสั่งเดียว</li><li><code>fly curve</code> บินโค้งผ่านจุดกลางไปยังปลายทาง</li><li><code>define function</code> ในหมวด Functions ใช้รวมท่าบินเป็นชุด</li><li>กดส่งออก Python เพื่อนำโค้ดไปรันกับ djitellopy จริง</li></ul><div class=\"note\"><b>ข้อจำกัดที่จำลองไว้</b> ระยะบินต่อคำสั่ง 20 ถึง 500 ซม. ความเร็ว 10 ถึง 100 ซม./วิ เพดานบิน 500 ซม. ตรงตามสเปกโดรนจริง</div>",
                "en": "<h3>Free mode - open arena</h3><p>No mission here, this is the sandbox for testing a program before flying it for real.</p><ul><li><code>go to x y z</code> flies straight to a point in one command</li><li><code>fly curve</code> arcs through a middle point</li><li><code>define function</code> in the Functions category groups manoeuvres</li><li>Export Python to run the same logic with djitellopy</li></ul><div class=\"note\"><b>Simulated limits</b> 20 to 500 cm per move, 10 to 100 cm/s, 500 cm ceiling, matching the real drone.</div>"])

let MISSION_TEXT: [String: MissionText] = [
    "basic": missionText_basic,
    "line": missionText_line,
    "square": missionText_square,
    "course": missionText_course,
    "show": missionText_show,
    "sensor": missionText_sensor,
    "variables": missionText_variables,
    "free": missionText_free
]
