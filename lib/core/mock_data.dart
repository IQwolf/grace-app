import 'package:grace_academy/data/models/course.dart';
import 'package:grace_academy/data/models/instructor.dart';
import 'package:grace_academy/data/models/lecture.dart';
import 'package:grace_academy/data/models/major.dart';
import 'package:grace_academy/data/models/user.dart';

class MockData {
  // Sample majors
  static const majors = [
    Major(id: '1', name: 'طب أسنان'),
    Major(id: '2', name: 'الطب البشري'),
    Major(id: '3', name: 'الصيدلة'),
    Major(id: '4', name: 'هندسة مدني'),
    Major(id: '5', name: 'هندسة كهرباء'),
    Major(id: '6', name: 'علوم حاسوب'),
    Major(id: '7', name: 'طب بيطري'),
    Major(id: '8', name: 'التمريض'),
  ];

  // Sample levels
  static const levels = [
    'الأولى',
    'الثانية',
    'الثالثة',
    'الرابعة',
    'الخامسة',
    'السادسة',
  ];

  // Sample governorates
  static const governorates = [
    'بغداد',
    'البصرة',
    'نينوى',
    'الأنبار',
    'أربيل',
    'كركوك',
    'السليمانية',
    'دهوك',
    'صلاح الدين',
    'ديالى',
    'كربلاء',
    'النجف',
    'القادسية',
    'المثنى',
    'ذي قار',
    'ميسان',
    'واسط',
    'بابل',
  ];

  // Sample universities
  static const universities = [
    'جامعة بغداد',
    'جامعة البصرة',
    'جامعة الموصل',
    'الجامعة التكنولوجية',
    'جامعة الأنبار',
    'جامعة كربلاء',
    'جامعة النجف',
    'جامعة كركوك',
    'جامعة السليمانية',
    'جامعة دهوك',
    'جامعة ديالى',
    'جامعة تكريت',
    'جامعة القادسية',
    'جامعة المثنى',
    'جامعة ذي قار',
    'جامعة ميسان',
    'جامعة واسط',
    'جامعة بابل',
  ];

  // Sample instructors
  static const instructors = [
    Instructor(
      id: '1',
      name: 'د. أحمد محمد',
      avatarUrl: 'https://picsum.photos/100/100?random=1',
    ),
    Instructor(
      id: '2',
      name: 'د. فاطمة علي',
      avatarUrl: 'https://picsum.photos/100/100?random=2',
    ),
    Instructor(
      id: '3',
      name: 'د. محمد حسن',
      avatarUrl: 'https://picsum.photos/100/100?random=3',
    ),
    Instructor(
      id: '4',
      name: 'د. زينب كاظم',
      avatarUrl: 'https://picsum.photos/100/100?random=4',
    ),
    Instructor(
      id: '5',
      name: 'د. عبد الله صالح',
      avatarUrl: 'https://picsum.photos/100/100?random=5',
    ),
    Instructor(
      id: '6',
      name: 'د. مريم أحمد',
      avatarUrl: 'https://picsum.photos/100/100?random=6',
    ),
  ];

  // Sample courses
  static const courses = [
    Course(
      id: '1',
      title: 'تشريح الأسنان',
      instructorId: '1',
      majorId: '1',
      level: 'الثانية',
      track: CourseTrack.first,
      coverUrl: 'https://picsum.photos/300/200?random=11',
      lecturesCount: 15,
      description: 'هذا الكورس يشرح تشريح الأسنان بشكل مفصل مع أمثلة وصور توضيحية. مناسب لطلبة طب الأسنان المرحلة الثانية.',
    ),
    Course(
      id: '2',
      title: 'أمراض اللثة',
      instructorId: '2',
      majorId: '1',
      level: 'الثالثة',
      track: CourseTrack.second,
      coverUrl: 'https://picsum.photos/300/200?random=12',
      lecturesCount: 12,
      description: 'تعرف على أهم أمراض اللثة وطرق التشخيص والعلاج مع حالات سريرية.',
    ),
    Course(
      id: '3',
      title: 'الجراحة العامة',
      instructorId: '3',
      majorId: '2',
      level: 'الرابعة',
      track: CourseTrack.first,
      coverUrl: 'https://picsum.photos/300/200?random=13',
      lecturesCount: 20,
      description: 'أساسيات الجراحة العامة، مبادئ التعقيم، التحضيرات، وأنواع العمليات الجراحية.',
    ),
    Course(
      id: '4',
      title: 'علم الأدوية',
      instructorId: '4',
      majorId: '3',
      level: 'الثالثة',
      track: CourseTrack.first,
      coverUrl: 'https://picsum.photos/300/200?random=14',
      lecturesCount: 18,
      description: 'مقدمة في علم الأدوية، آلية عمل الدواء، الحرائك الدوائية، والتداخلات الدوائية.',
    ),
    Course(
      id: '5',
      title: 'الهندسة الإنشائية',
      instructorId: '5',
      majorId: '4',
      level: 'الثانية',
      track: CourseTrack.second,
      coverUrl: 'https://picsum.photos/300/200?random=15',
      lecturesCount: 14,
      description: 'مفاهيم أساسية في التحليل والتصميم الإنشائي مع أمثلة تطبيقية.',
    ),
    Course(
      id: '6',
      title: 'الدوائر الكهربائية',
      instructorId: '6',
      majorId: '5',
      level: 'الأولى',
      track: CourseTrack.first,
      coverUrl: 'https://picsum.photos/300/200?random=16',
      lecturesCount: 16,
      description: 'مبادئ التيار والجهد، قوانين كيرشوف، تحليل الدوائر من الصفر.',
    ),
  ];

  // Sample lectures
  static const lectures = [
    // Course 1 - تشريح الأسنان
    Lecture(
      id: '1',
      courseId: '1',
      title: 'مقدمة في تشريح الأسنان',
      order: 1,
      isFree: true,
      videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      duration: Duration(minutes: 45, seconds: 30),
    ),
    Lecture(
      id: '2',
      courseId: '1',
      title: 'تشريح الأسنان الأمامية',
      order: 2,
      isFree: false,
      videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
      duration: Duration(minutes: 52, seconds: 15),
    ),
    Lecture(
      id: '3',
      courseId: '1',
      title: 'تشريح الأضراس',
      order: 3,
      isFree: false,
      videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      duration: Duration(minutes: 48, seconds: 45),
    ),

    // Course 2 - أمراض اللثة
    Lecture(
      id: '4',
      courseId: '2',
      title: 'مقدمة في أمراض اللثة',
      order: 1,
      isFree: true,
      videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      duration: Duration(minutes: 40, seconds: 20),
    ),
    Lecture(
      id: '5',
      courseId: '2',
      title: 'التهاب اللثة',
      order: 2,
      isFree: false,
      videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
      duration: Duration(minutes: 55, seconds: 10),
    ),

    // Course 3 - الجراحة العامة
    Lecture(
      id: '6',
      courseId: '3',
      title: 'مبادئ الجراحة',
      order: 1,
      isFree: true,
      videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      duration: Duration(minutes: 60, seconds: 0),
    ),

    // Course 4 - علم الأدوية
    Lecture(
      id: '7',
      courseId: '4',
      title: 'مقدمة في علم الأدوية',
      order: 1,
      isFree: true,
      videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      duration: Duration(minutes: 35, seconds: 45),
    ),

    // Course 5 - الهندسة الإنشائية
    Lecture(
      id: '8',
      courseId: '5',
      title: 'أساسيات الإنشاء',
      order: 1,
      isFree: true,
      videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      duration: Duration(minutes: 50, seconds: 30),
    ),

    // Course 6 - الدوائر الكهربائية
    Lecture(
      id: '9',
      courseId: '6',
      title: 'مقدمة في الدوائر الكهربائية',
      order: 1,
      isFree: true,
      videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      duration: Duration(minutes: 42, seconds: 15),
    ),
  ];

  // Sample hero slider images
  static const heroImages = [
    'https://picsum.photos/800/400?random=21',
    'https://picsum.photos/800/400?random=22',
    'https://picsum.photos/800/400?random=23',
    'https://picsum.photos/800/400?random=24',
  ];

  // Mock user for testing
  static final sampleUser = User(
    id: 'user_1',
    phone: '+9647712345678',
    name: 'أحمد محمد علي',
    governorate: 'بغداد',
    university: 'جامعة بغداد',
    birthDate: DateTime(1995, 5, 15),
    gender: Gender.male,
  );

  // Valid OTP for testing
  static const validOTP = '123456';
}