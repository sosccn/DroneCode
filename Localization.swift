import Foundation

enum Lang: String { case th, en }

var CURRENT_LANG: Lang = .th

private let i18nPart1: [String: [String: String]] = [
    "editor.dragTip": ["th": "ปัดซ้ายขวาเพื่อดูบล็อกอื่น แตะบล็อกค้างไว้แล้วลากขึ้นไปวางในโปรแกรม", "en": "Swipe to browse, press and hold a block then drag it up into the program"],
    "editor.dragHint": ["th": "แตะบล็อกในแถบด้านล่างค้างไว้ แล้วลากขึ้นมาวางตรงแถบสีฟ้า", "en": "Press and hold a block in the tray, then drag it onto the blue drop line"],
    "editor.tapToRun": ["th": "แตะเพื่อรัน", "en": "tap to run"],
    "editor.trash": ["th": "ลากมาปล่อยตรงนี้เพื่อลบบล็อก", "en": "Drop here to delete"],
    "editor.trashOver": ["th": "ปล่อยเพื่อลบ", "en": "Release to delete"],
    "toast.blockDeleted": ["th": "ลบบล็อกแล้ว", "en": "Block deleted"],
    "editor.delete": ["th": "ลบบล็อกนี้", "en": "Delete block"],
    "editor.done": ["th": "เสร็จ", "en": "Done"],
    "editor.value": ["th": "ค่า", "en": "Value"],
    "editor.kind": ["th": "ชนิดของค่า", "en": "Kind"],
    "editor.variable": ["th": "ตัวแปร", "en": "Variable"],
    "editor.sensor": ["th": "เซ็นเซอร์", "en": "Sensor"],
    "editor.operator": ["th": "ตัวดำเนินการ", "en": "Operator"],
    "editor.cancel": ["th": "ยกเลิก", "en": "Cancel"],
    "props.add": ["th": "วางสิ่งกีดขวาง", "en": "Place object"],
    "props.ring": ["th": "ห่วง", "en": "gate"],
    "props.wall": ["th": "กำแพง", "en": "wall"],
    "props.clear": ["th": "ล้างของที่วางเอง", "en": "Clear placed objects"],
    "props.none": ["th": "ยังไม่ได้วางอะไรลงสนาม", "en": "Nothing placed yet"],
    "props.select": ["th": "เลือกวัตถุ", "en": "Select object"],
    "props.delete": ["th": "ลบวัตถุนี้", "en": "Delete"]
]

private let i18nPart2: [String: [String: String]] = [
    "props.close": ["th": "ปิดแผงจัดวาง", "en": "Close"],
    "props.side": ["th": "ซ้าย/ขวา", "en": "Left/right"],
    "props.depth": ["th": "หน้า/หลัง", "en": "Forward/back"],
    "props.height": ["th": "ความสูง", "en": "Height"],
    "props.rot": ["th": "หมุน", "en": "Turn"],
    "props.width": ["th": "ความกว้าง", "en": "Width"],
    "props.title": ["th": "จัดวางสนามเอง", "en": "Arena editor"],
    "log.propAdd": ["th": "วาง{0}ลงในสนามแล้ว ปรับตำแหน่งได้จากแผงจัดวาง", "en": "Placed a {0}. Adjust it from the arena editor."],
    "log.propClear": ["th": "ล้างสิ่งที่วางเองออกจากสนามแล้ว", "en": "Cleared every placed object."],
    "toast.propMission": ["th": "เปลี่ยนบทเรียนแล้ว สิ่งที่วางเองถูกล้างออก", "en": "Lesson changed, placed objects were cleared"],
    "btn.lessonHide": ["th": "ซ่อนบทเรียน", "en": "Hide lesson"],
    "app.sub": ["th": "ห้องเรียนเขียนโปรแกรมโดรนด้วยบล็อกคำสั่ง พร้อมสนามบินจำลอง 3 มิติ", "en": "Learn drone programming with blocks in a live 3D flight simulator"],
    "btn.run": ["th": "รันโปรแกรม", "en": "Run"],
    "btn.stop": ["th": "หยุด", "en": "Stop"],
    "btn.reset": ["th": "รีเซ็ต", "en": "Reset"],
    "btn.retry": ["th": "ลองโหลดใหม่", "en": "Reload"]
]

private let i18nPart3: [String: [String: String]] = [
    "speed.label": ["th": "ความเร็ว", "en": "Speed"],
    "btn.pause": ["th": "พัก", "en": "Pause"],
    "btn.resume": ["th": "ไปต่อ", "en": "Resume"],
    "btn.landscape": ["th": "โหมดแนวนอน", "en": "Landscape mode"],
    "btn.portrait": ["th": "กลับแนวตั้ง", "en": "Back to portrait"],
    "btn.lesson": ["th": "เปิดบทเรียน", "en": "Open lesson"],
    "sheet.title": ["th": "ข้อมูลการบินและคอนโซล", "en": "Flight data and console"],
    "hud.toggle": ["th": "สถานะการบิน", "en": "Flight status"],
    "view.lesson": ["th": "บทเรียน", "en": "Lesson"],
    "view.code": ["th": "เขียนโค้ด", "en": "Code"],
    "view.flight": ["th": "สนามบิน", "en": "Arena"],
    "tab.lesson": ["th": "บทเรียน", "en": "Lesson"],
    "tab.reference": ["th": "คู่มือ", "en": "Reference"],
    "ref.intro": ["th": "บล็อกทั้งหมดที่ใช้ได้ พร้อมคำสั่งจริงของโดรนและโค้ด Python ที่ระบบสร้างให้", "en": "Every block, with the real drone command and the Python it generates."],
    "ref.flight": ["th": "การบินพื้นฐาน", "en": "Flight"],
    "ref.move": ["th": "การเคลื่อนที่", "en": "Movement"]
]

private let i18nPart4: [String: [String: String]] = [
    "ref.turn": ["th": "การหมุน", "en": "Rotation"],
    "ref.light": ["th": "ไฟและการแสดงผล", "en": "Lights and output"],
    "ref.sense": ["th": "เซ็นเซอร์และเงื่อนไข", "en": "Sensors and conditions"],
    "ref.logic": ["th": "ตรรกะ ลูป และตัวแปร", "en": "Logic, loops and variables"],
    "toast.landscapeOn": ["th": "เข้าสู่โหมดแนวนอนแล้ว", "en": "Landscape mode on"],
    "toast.landscapeOff": ["th": "กลับสู่โหมดแนวตั้งแล้ว", "en": "Back to portrait"],
    "toast.landscapeCss": ["th": "อุปกรณ์นี้ล็อกการหมุนจอไม่ได้ ระบบจึงหมุนหน้าจอให้แทน", "en": "This device cannot lock rotation, so the screen was rotated instead"],
    "log.paused": ["th": "พักการทำงานชั่วคราว", "en": "Program paused."],
    "log.resumed": ["th": "ทำงานต่อ", "en": "Program resumed."],
    "log.blockWarn": ["th": "ทำเครื่องหมายบล็อกที่มีปัญหาไว้ในพื้นที่เขียนโปรแกรมแล้ว", "en": "The block that failed is marked in the editor."],
    "btn.exportCmd": ["th": "ส่งออกคำสั่ง", "en": "Export commands"],
    "btn.exportPy": ["th": "ส่งออก Python", "en": "Export Python"],
    "speed.slow": ["th": "0.5x ช้า", "en": "0.5x slow"],
    "speed.normal": ["th": "1x ปกติ", "en": "1x normal"],
    "speed.fast": ["th": "2x เร็ว", "en": "2x fast"],
    "speed.vfast": ["th": "4x เร็วมาก", "en": "4x fastest"]
]

private let i18nPart5: [String: [String: String]] = [
    "panel.lesson": ["th": "บทเรียน", "en": "Lesson"],
    "panel.editor": ["th": "เขียนโปรแกรม", "en": "Blocks"],
    "panel.stage": ["th": "สนามบิน", "en": "Arena"],
    "editor.example": ["th": "ตัวอย่าง", "en": "Example"],
    "editor.tidy": ["th": "จัดเรียง", "en": "Tidy"],
    "editor.clear": ["th": "ล้าง", "en": "Clear"],
    "editor.save": ["th": "บันทึก", "en": "Save"],
    "editor.load": ["th": "เปิด", "en": "Open"],
    "editor.blocks": ["th": "{0} บล็อก", "en": "{0} blocks"],
    "cam.orbit": ["th": "มุมอิสระ", "en": "Orbit"],
    "cam.follow": ["th": "กล้องตาม", "en": "Follow"],
    "cam.fpv": ["th": "มุมนักบิน", "en": "FPV"],
    "cam.top": ["th": "มุมสูง", "en": "Top"],
    "hud.status": ["th": "สถานะ", "en": "Status"],
    "hud.alt": ["th": "ความสูง", "en": "Altitude"],
    "hud.yaw": ["th": "หัวโดรน", "en": "Heading"]
]

private let i18nPart6: [String: [String: String]] = [
    "hud.front": ["th": "สิ่งกีดขวางหน้า", "en": "Front sensor"],
    "hud.rings": ["th": "ห่วง", "en": "Gates"],
    "tele.x": ["th": "ตำแหน่ง X", "en": "Position X"],
    "tele.y": ["th": "ความสูง Y", "en": "Altitude Y"],
    "tele.z": ["th": "ตำแหน่ง Z", "en": "Position Z"],
    "tele.speed": ["th": "ความเร็ว", "en": "Speed"],
    "tele.led": ["th": "ไฟ LED", "en": "LED"],
    "tele.battery": ["th": "แบตเตอรี่", "en": "Battery"],
    "tele.time": ["th": "เวลาบิน", "en": "Flight time"],
    "tab.log": ["th": "บันทึก", "en": "Console"],
    "tab.cmd": ["th": "คำสั่ง Tello", "en": "Tello"],
    "tab.py": ["th": "Python", "en": "Python"],
    "view.hint": ["th": "ลากเพื่อหมุนมุมมอง หนีบสองนิ้วเพื่อซูม", "en": "Drag to orbit, pinch to zoom"],
    "badge.notyet": ["th": "ยังไม่ผ่าน", "en": "Not passed"],
    "badge.pass": ["th": "ผ่านภารกิจ", "en": "Mission passed"],
    "badge.fail": ["th": "ยังไม่ผ่าน", "en": "Not passed"]
]

private let i18nPart7: [String: [String: String]] = [
    "badge.flying": ["th": "กำลังบิน", "en": "Flying"],
    "lesson.goal": ["th": "เป้าหมาย: {0}", "en": "Goal: {0}"],
    "lesson.rings": ["th": "ห่วง {0} วง", "en": "{0} gates"],
    "lesson.obstacles": ["th": "สิ่งกีดขวาง {0} ชิ้น", "en": "{0} obstacles"],
    "lesson.tip": ["th": "กดปุ่มรันโปรแกรมเพื่อให้โดรนทำงานตามบล็อก ดูคำสั่งจริงและโค้ด Python ได้ที่แท็บด้านล่างของสนามจำลอง", "en": "Press Run to fly the program. The tabs under the arena show the real Tello commands and the generated Python code."],
    "overlay.blockly": ["th": "กำลังโหลดเอนจิ้นบล็อก Blockly", "en": "Loading the Blockly engine"],
    "overlay.blockly.sub": ["th": "มองหาไฟล์ blockly.min.js ที่อยู่ข้างไฟล์นี้ก่อน ถ้าไม่พบจึงค่อยโหลดจากอินเทอร์เน็ต", "en": "Looks for blockly.min.js next to this file first, and only then falls back to the internet"],
    "overlay.three": ["th": "กำลังโหลดเอนจิ้น 3 มิติ Three.js", "en": "Loading the Three.js 3D engine"],
    "overlay.three.sub": ["th": "เตรียมสนามบินจำลองและตัวโดรน", "en": "Preparing the arena and the drone"],
    "overlay.setup": ["th": "กำลังจัดห้องเรียน", "en": "Setting up the workspace"],
    "overlay.errBlockly": ["th": "โหลดเอนจิ้นบล็อกไม่สำเร็จ", "en": "Could not load the block engine"],
    "overlay.errOffline": ["th": "วางไฟล์ blockly.min.js และ three.min.js ไว้โฟลเดอร์เดียวกับไฟล์นี้ แล้วเปิดใหม่", "en": "Put blockly.min.js and three.min.js in the same folder as this file, then reload"],
    "overlay.errInject": ["th": "เปิดพื้นที่เขียนบล็อกไม่สำเร็จ", "en": "Could not open the block editor"],
    "fallback.3d": ["th": "เปิดสนามจำลอง 3 มิติไม่ได้ อุปกรณ์นี้อาจปิด WebGL หรือโหลด Three.js ไม่สำเร็จ ส่วนเขียนบล็อกยังใช้งานได้ตามปกติ", "en": "The 3D arena could not start. WebGL may be disabled or Three.js failed to load. The block editor still works."],
    "status.ready": ["th": "พร้อมบิน", "en": "Ready"],
    "status.takeoff": ["th": "กำลังบินขึ้น", "en": "Taking off"]
]

private let i18nPart8: [String: [String: String]] = [
    "status.hover": ["th": "ลอยนิ่ง", "en": "Hovering"],
    "status.landing": ["th": "กำลังลงจอด", "en": "Landing"],
    "status.landed": ["th": "ลงจอดแล้ว", "en": "Landed"],
    "status.move": ["th": "กำลังบิน", "en": "Flying"],
    "status.rotate": ["th": "กำลังหมุนตัว", "en": "Rotating"],
    "status.flip": ["th": "กำลังตีลังกา", "en": "Flipping"],
    "status.goto": ["th": "บินไปยังพิกัด", "en": "Going to point"],
    "status.curve": ["th": "บินเป็นเส้นโค้ง", "en": "Flying a curve"],
    "status.stopped": ["th": "หยุดกลางคัน", "en": "Stopped"],
    "status.emergency": ["th": "หยุดฉุกเฉิน", "en": "Emergency stop"],
    "status.waiting": ["th": "รอเงื่อนไข", "en": "Waiting"],
    "log.ready": ["th": "ระบบพร้อมใช้งาน เลือกบทเรียนแล้วลากบล็อกมาต่อกันได้เลย", "en": "System ready. Pick a lesson and start dragging blocks."],
    "log.start": ["th": "เริ่มรันโปรแกรม ภารกิจ {0}", "en": "Running program. Mission: {0}"],
    "log.done": ["th": "รันโปรแกรมครบทุกคำสั่งแล้ว", "en": "Program finished."],
    "log.aborted": ["th": "ผู้ใช้สั่งหยุดการทำงาน", "en": "Stopped by the user."],
    "log.reset": ["th": "รีเซ็ตโดรนกลับจุดเริ่มต้น", "en": "Drone reset to the start pad."]
]

private let i18nPart9: [String: [String: String]] = [
    "log.mission": ["th": "เปลี่ยนบทเรียนเป็น {0}", "en": "Lesson changed to {0}"],
    "log.takeoff": ["th": "บินขึ้นสู่ความสูง 100 ซม.", "en": "Taking off to 100 cm."],
    "log.land": ["th": "กำลังลดระดับลงจอด", "en": "Descending to land."],
    "log.landed": ["th": "ลงจอดเรียบร้อย มอเตอร์หยุดทำงาน", "en": "Landed, motors stopped."],
    "log.emergency": ["th": "หยุดมอเตอร์ฉุกเฉิน โดรนร่วงลงพื้น", "en": "Emergency stop, the drone drops."],
    "log.stop": ["th": "หยุดเคลื่อนที่และลอยนิ่งอยู่กับที่", "en": "Stopping and hovering in place."],
    "log.hover": ["th": "ลอยนิ่ง {0} วินาที", "en": "Hovering for {0} s."],
    "log.move": ["th": "บิน{0} {1} ซม. ที่ความเร็ว {2} ซม./วิ", "en": "Flying {0} {1} cm at {2} cm/s."],
    "log.rotate": ["th": "หมุน{0} {1} องศา", "en": "Rotating {0} {1} degrees."],
    "log.flip": ["th": "ตีลังกาไปทาง{0}", "en": "Flipping {0}."],
    "log.led": ["th": "ตั้งไฟ LED เป็นสี {0}", "en": "LED set to {0}."],
    "log.ledrgb": ["th": "ตั้งไฟ LED เป็นค่า RGB ({0}, {1}, {2})", "en": "LED set to RGB ({0}, {1}, {2})."],
    "log.speed": ["th": "ตั้งความเร็วเป็น {0} ซม./วินาที", "en": "Speed set to {0} cm/s."],
    "log.goto": ["th": "บินไปพิกัด ({0}, {1}, {2})", "en": "Going to ({0}, {1}, {2})."],
    "log.curve": ["th": "บินโค้งผ่านจุด ({0}, {1}, {2}) ไปยัง ({3}, {4}, {5})", "en": "Curving through ({0}, {1}, {2}) to ({3}, {4}, {5})."],
    "log.print": ["th": "พิมพ์ข้อความ: {0}", "en": "print: {0}"]
]

private let i18nPart10: [String: [String: String]] = [
    "log.loop": ["th": "เริ่มทำซ้ำ {0} รอบ", "en": "Loop starts, {0} rounds."],
    "log.loopEmpty": ["th": "บล็อกวนซ้ำยังว่างอยู่ ไม่มีคำสั่งข้างใน", "en": "The loop body is empty."],
    "log.ring": ["th": "ผ่านห่วงที่ {0} แล้ว", "en": "Gate {0} cleared."],
    "log.crash": ["th": "โดรนชนสิ่งกีดขวาง ภารกิจถือว่าล้มเหลว", "en": "The drone hit an obstacle. Mission failed."],
    "log.lowbat": ["th": "แบตเตอรี่เหลือน้อยกว่า 20% โดรนจริงจะเริ่มบังคับลงจอด", "en": "Battery below 20%. A real drone would force a landing."],
    "log.errNotFlying": ["th": "{0} ไม่สำเร็จ โดรนยังไม่ได้บินขึ้น (ต้องใช้บล็อก take off ก่อน)", "en": "{0} failed: the drone has not taken off yet (use \"take off\" first)."],
    "log.errFlipLow": ["th": "ตีลังกาไม่ได้ ต้องสูงอย่างน้อย 80 ซม. ตอนนี้ {0} ซม.", "en": "Flip refused: altitude must be at least 80 cm, now {0} cm."],
    "log.warnFloor": ["th": "บินต่ำกว่า 20 ซม. ไม่ได้ ระบบปรับความสูงไว้ที่ 20 ซม.", "en": "Cannot fly below 20 cm, clamped to 20 cm."],
    "log.warnCeiling": ["th": "เพดานบินสูงสุด 500 ซม. ระบบตัดความสูงไว้ที่ 500 ซม.", "en": "Ceiling is 500 cm, clamped to 500 cm."],
    "log.warnFlying": ["th": "โดรนบินอยู่แล้ว ข้ามคำสั่งบินขึ้น", "en": "Already flying, take off skipped."],
    "log.warnGround": ["th": "โดรนอยู่บนพื้นแล้ว ข้ามคำสั่งลงจอด", "en": "Already on the ground, land skipped."],
    "log.unknown": ["th": "ยังไม่รองรับบล็อก {0} จึงข้ามไป", "en": "Block {0} is not supported and was skipped."],
    "log.waitUntil": ["th": "รอจนกว่าเงื่อนไขจะเป็นจริง", "en": "Waiting until the condition becomes true."],
    "log.waitTimeout": ["th": "รอเงื่อนไขนานเกิน 20 วินาที ระบบข้ามคำสั่งนี้", "en": "Waited over 20 s, the block was skipped."],
    "log.limit": ["th": "วนซ้ำเกิน {0} รอบ ระบบหยุดลูปเพื่อความปลอดภัย", "en": "Loop exceeded {0} rounds and was stopped."],
    "log.callProc": ["th": "เรียกใช้ฟังก์ชัน {0}", "en": "Calling function {0}."]
]

private let i18nPart11: [String: [String: String]] = [
    "log.procMissing": ["th": "ไม่พบฟังก์ชัน {0}", "en": "Function {0} was not found."],
    "log.varSet": ["th": "ตั้งค่าตัวแปร {0} = {1}", "en": "Variable {0} = {1}"],
    "toast.noProgram": ["th": "ยังไม่มีคำสั่ง ลากบล็อกมาต่อใต้บล็อก when program starts ก่อน", "en": "No commands yet. Attach blocks under \"when program starts\"."],
    "toast.saved": ["th": "บันทึกไฟล์โปรเจกต์แล้ว", "en": "Project saved."],
    "toast.loaded": ["th": "เปิดไฟล์โปรเจกต์เรียบร้อย", "en": "Project opened."],
    "toast.loadErr": ["th": "เปิดไฟล์ไม่สำเร็จ: {0}", "en": "Could not open the file: {0}"],
    "toast.saveErr": ["th": "บันทึกไม่สำเร็จ: {0}", "en": "Could not save: {0}"],
    "toast.cleared": ["th": "ล้างพื้นที่ทำงานแล้ว", "en": "Workspace cleared."],
    "toast.example": ["th": "โหลดตัวอย่างเฉลยของบทนี้แล้ว ลองกดรันดู", "en": "Example program loaded. Press Run."],
    "toast.noExample": ["th": "บทนี้ยังไม่มีตัวอย่างเฉลย", "en": "No example for this lesson."],
    "toast.noCmd": ["th": "ยังไม่มีคำสั่ง ลองรันโปรแกรมก่อน", "en": "No commands yet, run the program first."],
    "toast.exported": ["th": "ส่งออกไฟล์แล้ว", "en": "File exported."],
    "chk.pass": ["th": "ทำภารกิจสำเร็จ", "en": "Mission accomplished."],
    "chk.noTakeoff": ["th": "ยังไม่มีคำสั่งบินขึ้น", "en": "The drone never took off."],
    "chk.noLand": ["th": "โดรนยังไม่ได้ลงจอด", "en": "The drone has not landed."],
    "chk.hasErrors": ["th": "มีคำสั่งที่ทำงานผิดพลาด ลองอ่านบันทึกการทำงาน", "en": "Some commands failed, check the console."]
]

private let i18nPart12: [String: [String: String]] = [
    "chk.tooShort": ["th": "บินออกไปได้แค่ {0} ซม. ยังไม่ถึง 90 ซม.", "en": "Flew only {0} cm, at least 90 cm is required."],
    "chk.notBack": ["th": "ลงจอดห่างจุดเดิม {0} ซม.", "en": "Landed {0} cm away from the start pad."],
    "chk.rings": ["th": "ผ่านห่วงแล้ว {0} จาก {1} วง", "en": "Cleared {0} of {1} gates."],
    "chk.noLoop": ["th": "ยังไม่ได้ใช้บล็อกวนซ้ำ repeat", "en": "The repeat loop block was not used."],
    "chk.noWhile": ["th": "ยังไม่ได้ใช้บล็อกเงื่อนไข repeat until หรือ if", "en": "A repeat until or if block was not used."],
    "chk.noFor": ["th": "ยังไม่ได้ใช้บล็อก count with i", "en": "The count-with-i loop was not used."],
    "chk.noFlip": ["th": "ยังไม่มีการตีลังกาสำเร็จ", "en": "No successful flip."],
    "chk.noLed": ["th": "ยังไม่ได้เปลี่ยนสีไฟ LED", "en": "The LED colour was never changed."],
    "chk.crashed": ["th": "โดรนชนสิ่งกีดขวาง", "en": "The drone crashed into an obstacle."],
    "chk.stopFar": ["th": "หยุดห่างกำแพง {0} ซม. ต้องอยู่ในช่วง 60 ถึง 140 ซม.", "en": "Stopped {0} cm from the wall, it must be between 60 and 140 cm."],
    "chk.lowAlt": ["th": "ขึ้นได้สูงสุด {0} ซม. ต้องถึง 250 ซม.", "en": "Reached only {0} cm, 250 cm is required."]
]

let I18N: [String: [String: String]] = {
    var table: [String: [String: String]] = [:]
    let parts: [[String: [String: String]]] = [
        i18nPart1, i18nPart2, i18nPart3, i18nPart4, i18nPart5, i18nPart6, i18nPart7, i18nPart8, i18nPart9, i18nPart10, i18nPart11, i18nPart12
    ]
    for part in parts {
        table.merge(part) { current, _ in current }
    }
    return table
}()

func t(_ key: String, _ args: [CustomStringConvertible] = []) -> String {
    guard let row = I18N[key] else { return key }
    var s = row[CURRENT_LANG.rawValue] ?? row["en"] ?? key
    for (i, a) in args.enumerated() {
        s = s.replacingOccurrences(of: "{\(i)}", with: String(describing: a))
    }
    return s
}
