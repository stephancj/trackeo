import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { User, UserRole } from './src/users/user.entity';
import * as bcrypt from 'bcrypt';

const dataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USER || 'trackeo',
  password: process.env.DB_PASS || 'Password_1234',
  database: process.env.DB_NAME || 'traccar_db',
  entities: [User],
  synchronize: false,
});

async function seed() {
  await dataSource.initialize();
  
  const userRepo = dataSource.getRepository(User);
  
  // Check if admin already exists
  const existingAdmin = await userRepo.findOne({ 
    where: { email: 'admin@trackeo.mg' } 
  });
  
  if (existingAdmin) {
    console.log('Admin user already exists');
    await dataSource.destroy();
    return;
  }
  
  // Hash password
  const hashedPassword = await bcrypt.hash('trackeo123', 10);
  
  // Create admin user
  const admin = userRepo.create({
    email: 'admin@trackeo.mg',
    password: hashedPassword,
    name: 'Admin',
    role: UserRole.ADMIN,
    isActive: true,
    alertsEnabled: true,
    alertSos: true,
    alertLowBattery: true,
    alertSpeedLimit: false,
    alertViaPush: true,
    alertViaWhatsapp: false,
  });
  
  await userRepo.save(admin);
  console.log('Admin user created: admin@trackeo.mg / trackeo123');
  
  await dataSource.destroy();
}

seed().catch(console.error);