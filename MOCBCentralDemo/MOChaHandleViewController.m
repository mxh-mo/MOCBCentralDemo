//
//  MOChaViewController.m
//  MOBleDemo
//
//  Created by 莫晓卉 on 2018/12/10.
//  Copyright © 2018 moxiaohui. All rights reserved.
//

#import "MOChaHandleViewController.h"
#import "MOPersViewController.h"
#import "MOBLEManager.h"
#define kTopHeight (CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame) + 44)
#define kBtnWidth (ceil(self.view.frame.size.width - 40)/3)

@interface MOChaHandleViewController () <MOBLEManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIButton *readBtn;
@property (nonatomic, strong) UIButton *writeBtn;
@property (nonatomic, strong) UIButton *subscibeBtn;
@property (nonatomic, strong) UILabel *nameLb;
@property (nonatomic, strong) CBCharacteristic *cha;
@end

@implementation MOChaHandleViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupView];
}

- (void)setupView {
  self.title = @"特性Detail";
  CGFloat topHeight = CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame) + 44;
  self.automaticallyAdjustsScrollViewInsets = NO;
  self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topHeight, self.view.frame.size.width, self.view.frame.size.height - topHeight) style:UITableViewStylePlain];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
  self.tableView.tableFooterView = view;
  [self.view addSubview:self.tableView];
  
  //  TODO
  self.view.backgroundColor = UIColor.whiteColor;
  [self.view addSubview:self.readBtn];
  [self.view addSubview:self.writeBtn];
  [self.view addSubview:self.subscibeBtn];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStyleDone target:self action:@selector(back)];
}

- (void)setCha:(CBCharacteristic *)cha string:(NSString *)string {
  _cha = cha;
  self.nameLb.text = string;
  self.readBtn.enabled = [string containsString:@"可读"];
  self.writeBtn.enabled = [string containsString:@"可写"];
  self.subscibeBtn.enabled = [string containsString:@"可订阅"];
  [self.tableView reloadData];
  [[MOBLEManager shareInstance] addDelegate:self];
  [[MOBLEManager shareInstance] discoverDescriptorsForCharacteristic:_cha]; // 搜索description
}

#pragma mark - MOBLEManagerDelegate
- (void)didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  [self.tableView reloadData];
}

- (void)didUpdateValueForCharacteristic {
  [self.tableView reloadData];
}


- (void)clickReadBtn {
  [[MOBLEManager shareInstance] readCharacteristic:self.cha];
}

- (void)clickWriteBtn {
  [[MOBLEManager shareInstance] writeCharacteristic:self.cha];
}

- (void)clickSubscibeBtn {
  [[MOBLEManager shareInstance] notifyCharacteristic:self.cha];
}


#pragma mark - UITableViewDataSource & UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  // 给 description 写数据
//  CBDescriptor *des = self.cha.descriptors[indexPath.row];
//  uint16_t val = 0x0002;
//  NSData *data = [NSData dataWithBytes:(void *)&val length:sizeof(val)];
//  [[MOBLEManager shareInstance] writeValue:data forDescriptor:des];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIndentify = @"UITableViewCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentify];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentify];
  }
  cell.textLabel.font = [UIFont systemFontOfSize:14];
  cell.textLabel.numberOfLines = 0;
  cell.contentView.backgroundColor = indexPath.row % 2 == 0 ? UIColor.lightGrayColor : UIColor.whiteColor;
  CBDescriptor *des = self.cha.descriptors[indexPath.row];
  NSString *value = [[NSString alloc] initWithData:des.value encoding:NSUTF8StringEncoding];
  cell.textLabel.text = [NSString stringWithFormat:@"UUID:%@ \nvalue:%@", des.UUID.UUIDString, value];
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 50;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.cha.descriptors.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  return [UIView new];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  return self.headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 114;
}

- (void)back {
  [self.navigationController popToRootViewControllerAnimated:YES];
}

- (UIView *)headerView {
  if (!_headerView) {
    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 160)];
    _headerView.backgroundColor = UIColor.whiteColor;
    [_headerView addSubview:self.readBtn];
    [_headerView addSubview:self.writeBtn];
    [_headerView addSubview:self.subscibeBtn];
    [_headerView addSubview:self.nameLb];
  }
  return _headerView;
}

- (UILabel *)nameLb {
  if (!_nameLb) {
    _nameLb = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.readBtn.frame) + 10, self.view.frame.size.width - 20, 50)];
    _nameLb.textColor = UIColor.blueColor;
    _nameLb.font = [UIFont systemFontOfSize:14];
    _nameLb.numberOfLines = 0;
  }
  return _nameLb;
}

- (UIButton *)readBtn {
  if (!_readBtn) {
    _readBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_readBtn setTitle:@"读" forState:UIControlStateNormal];
    [_readBtn setTitle:@"不可读" forState:UIControlStateDisabled];
    _readBtn.backgroundColor = UIColor.blueColor;
    [_readBtn addTarget:self action:@selector(clickReadBtn) forControlEvents:UIControlEventTouchUpInside];
    _readBtn.frame = CGRectMake(10, 10, kBtnWidth, 44);
  }
  return _readBtn;
}

- (UIButton *)writeBtn {
  if (!_writeBtn) {
    _writeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_writeBtn setTitle:@"写" forState:UIControlStateNormal];
    [_writeBtn setTitle:@"不可写" forState:UIControlStateDisabled];
    _writeBtn.backgroundColor = UIColor.blueColor;
    [_writeBtn addTarget:self action:@selector(clickWriteBtn) forControlEvents:UIControlEventTouchUpInside];
    _writeBtn.frame = CGRectMake(20+kBtnWidth, 10, kBtnWidth, 44);
  }
  return _writeBtn;
}

- (UIButton *)subscibeBtn {
  if (!_subscibeBtn) {
    _subscibeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_subscibeBtn setTitle:@"订阅" forState:UIControlStateNormal];
    [_subscibeBtn setTitle:@"不可订阅" forState:UIControlStateDisabled];
    [_subscibeBtn setTitleColor:UIColor.redColor forState:UIControlStateHighlighted];
    _subscibeBtn.backgroundColor = UIColor.blueColor;
    [_subscibeBtn addTarget:self action:@selector(clickSubscibeBtn) forControlEvents:UIControlEventTouchUpInside];
    _subscibeBtn.frame = CGRectMake(30+kBtnWidth+kBtnWidth, 10, kBtnWidth, 44);
  }
  return _subscibeBtn;
}

@end
